import env from "@/config/env";
import { SYSTEM_FEATURES } from "@/constants/SYSTEM_FEATURES";
import { FeatureKey } from "@/enums/feature-key.enum";
import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { IProcessedRevenueCatEventRepository } from "@/interfaces/repositories/processed-revenuecat-event.repository.interface";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { FeatureFullPayload, FeatureLimitsOnlyPayload, ISubscriptionWebhookRepository, RevenueCatWebhookEventData } from "@/interfaces/repositories/subscription-webhook.repository.interface";
import { ISyncTransactionContext, IUserSubscriptionRepository, SubscriptionStatus } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { UserFeature } from "@/interfaces/services/user.feature.service.interface";
import { EnrichedPlanFeature, EnrichedSubscriptionPlan, EnrichedUserSubscription, IUserSubscriptionService, SubscriptionPlan, VerifyPurchaseParams } from "@/interfaces/services/user.subscription.service.interface";
import { NotificationType } from "@/constants/notificationTypes";
import { notificationService } from "../notification.service";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";

// ─── RevenueCat API types ────────────────────────────────────────────────────

type RevenueCatSubscription = {
   expires_date?: string;
   purchase_date?: string;
   unsubscribe_detected_at?: string;
};

type RevenueCatSubscriberResponse = {
   subscriber?: {
      original_app_user_id?: string;
      aliases?: string[];
      subscriptions?: Record<string, RevenueCatSubscription>;
   };
};

// ─── Constants ────────────────────────────────────────────────────────────────

const FREE_PLAN_NAME = "FREE";
const DEFAULT_SUBSCRIPTION_DURATION_DAYS = 30;
/**
 * FREE plan subscriptions use a 100-year endDate to avoid spurious local-clock
 * expiration inconsistency between auth service and expiration handler.
 */
const FREE_PLAN_DURATION_DAYS = 365 * 100;
const MS_PER_DAY = 24 * 60 * 60 * 1000;
/**
 * Minimum buffer applied to /sync before it can downgrade an active subscription
 * when RC shows no active product.  The check uses endDate (not createdAt) so a
 * user with a valid future endDate is never incorrectly downgraded due to stale
 * RC API cache.  5 minutes allows for immediate post-purchase RC propagation lag.
 */
const PURCHASE_SYNC_GRACE_PERIOD_MIN_MS = 5 * 60 * 1000; // 5 minutes
const REVENUECAT_API_TIMEOUT_MS = 10_000; // 10 seconds

// ─── Service ──────────────────────────────────────────────────────────────────

export class UserSubscriptionService implements IUserSubscriptionService {
   constructor(
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly userSubscriptionRepository: IUserSubscriptionRepository,
      private readonly processedRevenueCatEventRepository: IProcessedRevenueCatEventRepository,
      private readonly userFeatureRepository: IUserFeatureRepository,
      private readonly subscriptionWebhookRepository: ISubscriptionWebhookRepository,
      private readonly userRepository: IUserRepository,
      private readonly emailService: IEmailService
   ) {}

   // ── Public API ────────────────────────────────────────────────────────────

   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionPlanRepository.getAllPlansWithFeatures();
      return this.sortPlans(plans).map((plan) => this.enrichPlan(plan));
   }

   /**
    * Returns the user's active subscription.
    *
    * NOTE: This is now a PURE READ — it no longer writes to the database when a
    * local endDate has passed.  Expiration-driven state changes
    * are driven exclusively by RevenueCat EXPIRATION webhooks and the periodic
    * reconciliation job.  Relying on local endDate alone to downgrade would bypass
    * RevenueCat as the source of truth (e.g. it would ignore grace periods).
    */
   async getMySubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      const subscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      if (!subscription) {
         return null;
      }

      return {
         ...this.enrichUserSubscription(subscription),
         message: await this.buildSubscriptionMessage(subscription),
      };
   }

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   /**
    * Subscribes a user to a plan.
    *
    * SECURITY: This endpoint is restricted to the FREE plan only.  Any attempt to
    * activate a paid plan directly is rejected.  Paid plan
    * activations must go through the RevenueCat webhook or /sync endpoint so that
    * the store receipt is independently verified.
    */
   async subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription> {
      const plan = await this.getRequiredActivePlan(planId);
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan || plan.id !== freePlan.id) {
         throw new ApiError(403, "Direct plan subscription is not allowed. Paid plans must be purchased through the app store.");
      }

      const currentSubscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      // If the user already has an active FREE plan subscription, return it
      if (currentSubscription && currentSubscription.planId === freePlan.id) {
         return this.enrichUserSubscription(currentSubscription);
      }

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const startDate = new Date();
      const endDate = this.addDays(startDate, FREE_PLAN_DURATION_DAYS); // M-6

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: SubscriptionStatus.ACTIVE,
         startDate,
         endDate,
         willRenew: false, // FREE plan never auto-renews
      });

      await this.applyFeaturesForPlan(userId, plan, true /* resetUsage */);

      return this.enrichUserSubscription(subscription);
   }
   /**
    * Performs a lazy reconciliation of the user's subscription state with RevenueCat.
    * Checks if the subscription is in GRACE_PERIOD, BILLING_ISSUE, or expired,
    * and hits RevenueCat to sync the state without requiring a background cron job.
    */
   async reconcileUserSubscription(userId: number): Promise<void> {
      try {
         const subscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);
         if (!subscription) return;

         const now = new Date();
         const isGracePeriod = subscription.status === SubscriptionStatus.GRACE_PERIOD;
         const isBillingIssue = subscription.status === SubscriptionStatus.BILLING_ISSUE;
         const isEndDatePassed = subscription.endDate && new Date(subscription.endDate) < now;
         const isCancelled = subscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY;

         // We only hit RevenueCat if state is uncertain. If they have a valid end date
         // and are not in a failed billing state, we trust the DB and skip API calls.
         const needsReconciliation = isGracePeriod || isBillingIssue || (isEndDatePassed && !isCancelled);

         if (!needsReconciliation) {
            return;
         }

         logger.info(`[RECONCILIATION] Triggering lazy reconciliation for userId ${userId}. Status: ${subscription.status}`);

         // Fetch data from RevenueCat
         const revenueCatData = await this.getRevenueCatSubscriberData(userId);
         const activeProduct = this.findActiveRevenueCatProduct(revenueCatData);
         const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

         await this.userSubscriptionRepository.executeSyncTransaction(userId, async (ctx) => {
            const currentSub = await ctx.findActiveSubscriptionByUserId(userId);
            if (!currentSub || currentSub.id !== subscription.id) return;

            if (isGracePeriod) {
               if (activeProduct) {
                  const targetPlan = await this.subscriptionPlanRepository.findPlanByStoreProductId(activeProduct.productIdentifier);
                  if (targetPlan) {
                     logger.info(`[RECONCILIATION] RC confirms active product. Restoring GRACE_PERIOD -> ACTIVE for userId ${userId}.`);
                     await this.syncActivatePlan(ctx, userId, targetPlan.id, activeProduct.expiryTime || this.addDays(now, 30), activeProduct.willRenew, false, SubscriptionStatus.ACTIVE);
                     await this.writeSyncAuditLog(ctx, {
                        userId,
                        previousPlanId: currentSub.planId,
                        newPlanId: targetPlan.id,
                        previousStatus: currentSub.status,
                        newStatus: SubscriptionStatus.ACTIVE as any,
                        reason: "Lazy reconciliation recovered GRACE_PERIOD to ACTIVE",
                        source: "RECONCILIATION",
                     });
                  }
               } else if (currentSub.gracePeriodEndsAt && new Date(currentSub.gracePeriodEndsAt) < now) {
                  logger.info(`[RECONCILIATION] Grace period expired. Downgrading userId ${userId} to FREE.`);
                  await this.syncDowngradeToFree(ctx, userId, freePlan?.id);
               }
               return;
            }

            if (isBillingIssue) {
               if (activeProduct) {
                  const targetPlan = await this.subscriptionPlanRepository.findPlanByStoreProductId(activeProduct.productIdentifier);
                  if (targetPlan) {
                     logger.info(`[RECONCILIATION] RC confirms active product. Restoring BILLING_ISSUE -> ACTIVE for userId ${userId}.`);
                     await this.syncActivatePlan(ctx, userId, targetPlan.id, activeProduct.expiryTime || this.addDays(now, 30), activeProduct.willRenew, false, SubscriptionStatus.ACTIVE);
                     await this.writeSyncAuditLog(ctx, {
                        userId,
                        previousPlanId: currentSub.planId,
                        newPlanId: targetPlan.id,
                        previousStatus: currentSub.status,
                        newStatus: SubscriptionStatus.ACTIVE as any,
                        reason: "Lazy reconciliation recovered BILLING_ISSUE to ACTIVE",
                        source: "RECONCILIATION",
                     });
                  }
               } else if (isEndDatePassed) {
                  const gracePeriodEndsAt = this.addDays(new Date(currentSub.endDate), 7);
                  logger.info(`[RECONCILIATION] BILLING_ISSUE endDate passed. Moving userId ${userId} to GRACE_PERIOD.`);
                  await ctx.updateUserSubscription(currentSub.id, {
                     status: SubscriptionStatus.GRACE_PERIOD as any,
                     gracePeriodEndsAt,
                  });
                  await this.writeSyncAuditLog(ctx, {
                     userId,
                     previousPlanId: currentSub.planId,
                     newPlanId: currentSub.planId,
                     previousStatus: currentSub.status,
                     newStatus: SubscriptionStatus.GRACE_PERIOD as any,
                     reason: "Lazy reconciliation moved expired BILLING_ISSUE to GRACE_PERIOD",
                     source: "RECONCILIATION",
                  });
               }
               return;
            }

            if (isEndDatePassed && !isCancelled) {
               if (activeProduct) {
                  const targetPlan = await this.subscriptionPlanRepository.findPlanByStoreProductId(activeProduct.productIdentifier);
                  if (targetPlan) {
                     logger.info(`[RECONCILIATION] RC confirms active product. Renewing userId ${userId} to ACTIVE.`);
                     await this.syncActivatePlan(ctx, userId, targetPlan.id, activeProduct.expiryTime || this.addDays(now, 30), activeProduct.willRenew, false, SubscriptionStatus.ACTIVE);
                     await this.writeSyncAuditLog(ctx, {
                        userId,
                        previousPlanId: currentSub.planId,
                        newPlanId: targetPlan.id,
                        previousStatus: currentSub.status,
                        newStatus: SubscriptionStatus.ACTIVE as any,
                        reason: "Lazy reconciliation renewed expired subscription to ACTIVE",
                        source: "RECONCILIATION",
                     });
                  }
               } else {
                  logger.info(`[RECONCILIATION] endDate passed and no RC product. Moving userId ${userId} to FREE.`);
                  await this.syncDowngradeToFree(ctx, userId, freePlan?.id);
               }
            }
         });
      } catch (err: unknown) {
         logger.error(`[RECONCILIATION] Failed to reconcile subscription for userId ${userId}:`, err);
         // Swallow the error and allow the user to proceed with DB state.
      }
   }

   async syncSubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      logger.info(`[SYNC_SUBSCRIPTION] Starting sync for userId: ${userId}`);
      const revenueCatData = await this.getRevenueCatSubscriberData(userId);

      const originalUserIdStr = revenueCatData.subscriber?.original_app_user_id;

      logger.info(`[SYNC_SUBSCRIPTION] Identity check passed inherently by RevenueCat API. Fetched data for userId ${userId}. (original_app_user_id: '${originalUserIdStr}')`);

      const activeProduct = this.findActiveRevenueCatProduct(revenueCatData);

      await this.userSubscriptionRepository.executeSyncTransaction(userId, async (ctx) => {
         const currentSubscription = await ctx.findActiveSubscriptionByUserId(userId);
         const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

         logger.info(`[SYNC_SUBSCRIPTION] activeProduct: ${JSON.stringify(activeProduct)}, currentSubscription planId: ${currentSubscription?.planId}, freePlan id: ${freePlan?.id}`);

         if (!activeProduct) {
            // CRITICAL-1 fix: grace period logic is now based on the subscription's
            // endDate (RC-verified) rather than createdAt.  A user whose endDate is
            // still in the future is NEVER downgraded by /sync alone — expiration
            // must come from an EXPIRATION webhook or the reconciliation job.
            if (currentSubscription) {
               const now = new Date();
               const endDate = new Date(currentSubscription.endDate);
               const isEndDateInFuture = endDate > now;
               const timeSinceCreated = now.getTime() - currentSubscription.createdAt.getTime();
               const isWithinMinimumGrace = timeSinceCreated < PURCHASE_SYNC_GRACE_PERIOD_MIN_MS;

               logger.warn(`[SYNC_SUBSCRIPTION] No active product in RevenueCat for userId ${userId}. planId=${currentSubscription.planId}, endDate=${endDate.toISOString()}, isEndDateInFuture=${isEndDateInFuture}, isWithinMinimumGrace=${isWithinMinimumGrace}`);

               // Case 1: Subscription endDate is still in the future — trust the store
               if (isEndDateInFuture) {
                  logger.info(`[SYNC_SUBSCRIPTION] Subscription endDate is in the future (${endDate.toISOString()}). RC may be stale. Retaining current subscription — webhook or reconciliation job will handle expiration.`);
                  // Still update lastSyncedAt so reconciliation knows when we last checked
                  await ctx.updateUserSubscription(currentSubscription.id, { lastSyncedAt: now } as any);
                  return;
               }

               // Case 2: endDate has passed but we're within the 5-min minimum grace
               // (protects against race conditions right after purchase creation)
               if (isWithinMinimumGrace) {
                  logger.info(`[SYNC_SUBSCRIPTION] Within minimum sync grace period (${timeSinceCreated}ms < ${PURCHASE_SYNC_GRACE_PERIOD_MIN_MS}ms). Retaining current subscription.`);
                  return;
               }

               if (currentSubscription.planId === freePlan?.id) {
                  logger.info(`[SYNC_SUBSCRIPTION] No active product and user is already on FREE plan. Nothing to do.`);
                  return;
               }
            }
            logger.warn(`[SYNC_SUBSCRIPTION] Triggering downgradeToFreePlan for userId ${userId} because activeProduct is null and subscription endDate has passed.`);
            await this.syncDowngradeToFree(ctx, userId, freePlan?.id);
            return;
         }

         const targetPlan = await this.subscriptionPlanRepository.findPlanByStoreProductId(activeProduct.productIdentifier);
         logger.info(`[SYNC_SUBSCRIPTION] Product identifier '${activeProduct.productIdentifier}' mapped to targetPlan: ${targetPlan ? targetPlan.name + " (id: " + targetPlan.id + ")" : "NOT FOUND"}`);

         if (!targetPlan) {
            logger.error(`[SYNC_SUBSCRIPTION] Plan mapping for storeProductId '${activeProduct.productIdentifier}' not found on backend!`);
            throw new ApiError(404, `Plan mapping for product identifier '${activeProduct.productIdentifier}' not found on backend`);
         }

         const endDate = activeProduct.expiryTime ?? this.addDays(new Date(), DEFAULT_SUBSCRIPTION_DURATION_DAYS);

         const targetStatus = activeProduct.willRenew ? SubscriptionStatus.ACTIVE : SubscriptionStatus.CANCELLED_PENDING_EXPIRY;

         if (!currentSubscription || currentSubscription.planId === freePlan?.id) {
            logger.info(`[SYNC_SUBSCRIPTION] Activating new paid plan ${targetPlan.name} (id: ${targetPlan.id}) for userId ${userId}. endDate=${endDate.toISOString()}, willRenew=${activeProduct.willRenew}, status=${targetStatus}`);
            await this.syncActivatePlan(ctx, userId, targetPlan.id, endDate, activeProduct.willRenew, true /* resetUsage */, targetStatus);
            await this.writeSyncAuditLog(ctx, {
               userId,
               previousPlanId: currentSubscription?.planId,
               newPlanId: targetPlan.id,
               previousStatus: currentSubscription?.status ?? undefined,
               newStatus: targetStatus,
               reason: "Subscription activated via /sync — verified active product in RevenueCat",
               source: "SYNC",
            });
            return;
         }

         if (currentSubscription.planId === targetPlan.id) {
            let finalStatus = targetStatus;
            let finalWillRenew = activeProduct.willRenew;

            // CRITICAL-5 fix (C-9 improvement): Only trust DB/Webhook cancellation if
            // RC genuinely still shows the subscription as cancelled (unsubscribe_detected_at
            // is present). If RC shows willRenew=true with no unsubscribe_detected_at, the
            // user has re-enabled auto-renewal (UNCANCELLATION) and we must restore ACTIVE.
            if (
               currentSubscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY &&
               targetStatus === SubscriptionStatus.ACTIVE &&
               activeProduct.willRenew === true
            ) {
               // Check if the UNCANCELLATION was confirmed by RC (willRenew=true means unsubscribe_detected_at is null in the RC response)
               // RC's findActiveRevenueCatProduct already strips products with unsubscribe_detected_at, so willRenew=true here
               // means the user has genuinely re-enabled auto-renewal.
               logger.info(`[SYNC_SUBSCRIPTION] DB shows CANCELLED_PENDING_EXPIRY but RevenueCat confirms willRenew=true (genuine UNCANCELLATION). Restoring to ACTIVE.`);
               finalStatus = SubscriptionStatus.ACTIVE;
               finalWillRenew = true;
            } else if (
               currentSubscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY &&
               targetStatus === SubscriptionStatus.ACTIVE &&
               !activeProduct.willRenew
            ) {
               // RC still shows willRenew=false (unsubscribe_detected_at present) — trust DB cancellation
               logger.warn(`[SYNC_SUBSCRIPTION] DB shows CANCELLED_PENDING_EXPIRY and RevenueCat also shows willRenew=false. Trusting DB cancellation.`);
               finalStatus = SubscriptionStatus.CANCELLED_PENDING_EXPIRY;
               finalWillRenew = false;
            }

            // Also restore BILLING_ISSUE → ACTIVE when RC shows active product
            if (
               (currentSubscription.status === SubscriptionStatus.BILLING_ISSUE ||
                currentSubscription.status === SubscriptionStatus.GRACE_PERIOD) &&
               targetStatus === SubscriptionStatus.ACTIVE
            ) {
               logger.info(`[SYNC_SUBSCRIPTION] RC confirms active product. Restoring ${currentSubscription.status} → ACTIVE.`);
               finalStatus = SubscriptionStatus.ACTIVE;
               finalWillRenew = activeProduct.willRenew;
            }

            logger.info(`[SYNC_SUBSCRIPTION] Updating existing plan ${targetPlan.name} (id: ${targetPlan.id}) for userId ${userId}. endDate=${endDate.toISOString()}, willRenew=${finalWillRenew}, status=${finalStatus}`);
            await ctx.updateUserSubscription(currentSubscription.id, {
               endDate,
               willRenew: finalWillRenew,
               status: finalStatus as unknown as any,
               nextPlanId: null,
               lastSyncedAt: new Date(),
            });
            await this.writeSyncAuditLog(ctx, {
               userId,
               previousPlanId: currentSubscription.planId,
               newPlanId: targetPlan.id,
               previousStatus: currentSubscription.status,
               newStatus: finalStatus,
               reason: "Subscription renewed/refreshed via /sync — verified active product in RevenueCat",
               source: "SYNC",
            });
            return;
         }

         const currentPlan = await this.subscriptionPlanRepository.getPlanById(currentSubscription.planId);
         if (!currentPlan) throw new ApiError(404, "Current subscription plan not found");

         if (targetPlan.price >= currentPlan.price) {
            logger.info(`[SYNC_SUBSCRIPTION] Upgrading userId ${userId} from plan ${currentPlan.name} to ${targetPlan.name}`);
            await this.syncActivatePlan(ctx, userId, targetPlan.id, endDate, activeProduct.willRenew, false /* preserve usage */);
            await this.writeSyncAuditLog(ctx, {
               userId,
               previousPlanId: currentSubscription.planId,
               newPlanId: targetPlan.id,
               previousStatus: "ACTIVE",
               newStatus: "ACTIVE",
               reason: "Immediate upgrade via /sync",
               source: "SYNC",
            });
         } else {
            logger.info(`[SYNC_SUBSCRIPTION] Deferring downgrade for userId ${userId} from plan ${currentPlan.name} to ${targetPlan.name} until ${endDate.toISOString()}`);
            await ctx.updateUserSubscription(currentSubscription.id, {
               nextPlanId: targetPlan.id,
               willRenew: false,
               endDate, // C-5 fix: RC-verified endDate for accurate expiry
            });
            await this.writeSyncAuditLog(ctx, {
               userId,
               previousPlanId: currentSubscription.planId,
               newPlanId: targetPlan.id,
               previousStatus: "ACTIVE",
               newStatus: "ACTIVE",
               reason: "Deferred downgrade scheduled via /sync",
               source: "SYNC",
            });
         }
      });

      return this.getMySubscription(userId);
   }

   /**
    * Verifies a purchase with the RevenueCat REST API and immediately activates
    * the corresponding plan in the database.
    *
    * This is the preferred post-purchase path.  The Flutter app calls this
    * endpoint right after Purchases.purchasePackage() succeeds, providing the
    * originalTransactionId from CustomerInfo.  We look up that transaction
    * in the RC subscriber data, confirm it is active and not expired, then
    * activate the plan — all within a single request, without waiting for a
    * webhook to arrive.
    */
   async verifyAndActivatePurchase(userId: number, params: VerifyPurchaseParams): Promise<EnrichedUserSubscription> {
      logger.info(`[VERIFY_PURCHASE] Starting purchase verification for userId=${userId}, productId=${params.productId}, txnId=${params.originalTransactionId}`);

      // Fetch current RC subscriber data (same helper used by /sync)
      const revenueCatData = await this.getRevenueCatSubscriberData(userId);

      const subscriptions = revenueCatData.subscriber?.subscriptions ?? {};

      // Find the entry matching the provided originalTransactionId or productId.
      // RC returns subscriptions keyed by productIdentifier.
      let matchedProductIdentifier: string | null = null;
      let matchedExpiry: Date | null = null;
      let willRenew = true;

      for (const [productIdentifier, subscription] of Object.entries(subscriptions)) {
         const expiryTime = subscription.expires_date ? new Date(subscription.expires_date) : null;
         const isExpired = expiryTime ? expiryTime <= new Date() : false;

         // Match by productId OR by the fact that it is the only non-expired entry
         const isTargetProduct = productIdentifier === params.productId ||
            productIdentifier.startsWith(`${params.productId}:`);

         if (isTargetProduct && !isExpired) {
            matchedProductIdentifier = productIdentifier;
            matchedExpiry = expiryTime;
            willRenew = !subscription.unsubscribe_detected_at;
            break;
         }
      }

      if (!matchedProductIdentifier) {
         // The RC API doesn't yet show the transaction — fall back to /sync logic
         // which is more resilient to RC API propagation lag.
         logger.warn(`[VERIFY_PURCHASE] RC API does not yet show active product '${params.productId}' for userId=${userId}. Falling back to syncSubscription.`);
         const synced = await this.syncSubscription(userId);
         if (synced) return synced;
         throw new ApiError(404, `Purchase verification failed: product '${params.productId}' not found in RevenueCat. Please try again in a few seconds or restore purchases.`);
      }

      const targetPlan = await this.subscriptionPlanRepository.findPlanByStoreProductId(matchedProductIdentifier)
         ?? await this.subscriptionPlanRepository.findPlanByStoreProductId(params.productId);

      if (!targetPlan) {
         logger.error(`[VERIFY_PURCHASE] No backend plan mapped to product '${matchedProductIdentifier}'`);
         throw new ApiError(404, `No plan mapped to product '${matchedProductIdentifier}'. Contact support.`);
      }

      const now = new Date();
      const endDate = matchedExpiry ?? this.addDays(now, DEFAULT_SUBSCRIPTION_DURATION_DAYS);
      const targetStatus = willRenew ? SubscriptionStatus.ACTIVE : SubscriptionStatus.CANCELLED_PENDING_EXPIRY;

      await this.userSubscriptionRepository.executeSyncTransaction(userId, async (ctx) => {
         const currentSub = await ctx.findActiveSubscriptionByUserId(userId);
         const previousPlanId = currentSub?.planId ?? null;
         const previousStatus = currentSub?.status ?? undefined;

         // Deactivate previous subscriptions
         await ctx.deactivateUserSubscriptions(userId);

         // Create the new subscription record
         await ctx.createUserSubscription({
            userId: userId as any,
            planId: targetPlan.id as any,
            status: targetStatus as any,
            startDate: now,
            endDate,
            willRenew,
            originalTransactionId: params.originalTransactionId,
            store: params.store,
            environment: params.environment,
            lastEventTimestampMs: BigInt(now.getTime()) as any,
            user: { connect: { id: userId } },
            plan: { connect: { id: targetPlan.id } },
         } as any);

         // Apply features immediately
         const enrichedPlan = this.enrichPlan(targetPlan);
         const featurePayload = previousPlanId === null
            ? this.buildFeatureFullPayload(enrichedPlan)   // first purchase — reset usage
            : this.buildFeatureLimitsOnlyPayload(enrichedPlan); // upgrade — preserve usage

         await ctx.applyFeatures(userId, featurePayload);

         // Write audit log
         await this.writeSyncAuditLog(ctx, {
            userId,
            previousPlanId,
            newPlanId: targetPlan.id,
            previousStatus,
            newStatus: targetStatus,
            reason: `Purchase verified and activated immediately via /verify-purchase (product: ${matchedProductIdentifier}, txn: ${params.originalTransactionId})`,
            source: "VERIFY_PURCHASE",
            eventType: "INITIAL_PURCHASE",
            eventId: `verify_${params.originalTransactionId}_${now.getTime()}`,
            productId: matchedProductIdentifier,
            originalTransactionId: params.originalTransactionId,
            store: params.store,
            environment: params.environment,
         });

         logger.info(`[VERIFY_PURCHASE] Successfully activated plan '${targetPlan.name}' (id=${targetPlan.id}) for userId=${userId}. endDate=${endDate.toISOString()}, willRenew=${willRenew}`);
      });

      const result = await this.getMySubscription(userId);
      if (!result) throw new ApiError(500, "Subscription activation failed. Please contact support.");
      return result;
   }

   /**
    * Handles a RevenueCat webhook event.
    */
   async handleWebhook(payload: Record<string, unknown>, signatureHeader?: string): Promise<void> {
      const webhookSecret = env.REVENUECAT_WEBHOOK_SECRET;
      if (!signatureHeader || signatureHeader !== webhookSecret) {
         logger.warn("Webhook: rejected — invalid or missing Authorization header");
         throw new ApiError(401, "Unauthorized");
      }

      const event = payload.event as RevenueCatWebhookEventData | undefined;

      if (!event?.id || !event.type) {
         // Malformed payload — return 200 so RevenueCat does not retry
         logger.warn("Webhook: received malformed payload (missing event.id or event.type)");
         return;
      }

      // M-3: Log only safe fields, never the full event object
      logger.info("Webhook event received", {
         eventId: event.id,
         type: event.type,
         productId: event.product_id,
         store: event.store,
         environment: event.environment,
         timestampMs: event.event_timestamp_ms,
      });

      // ── Resolve userId ───────────────────────────────────────────────────────
      let userId: number | undefined;
      const potentialIds = [event.original_app_user_id, event.app_user_id, ...(event.aliases || [])];

      for (const idStr of potentialIds) {
         if (!idStr) continue;
         const parsed = Number.parseInt(idStr, 10);
         if (!Number.isNaN(parsed) && parsed > 0) {
            userId = parsed;
            break;
         }
      }

      if (userId === undefined) {
         logger.warn("Webhook: could not resolve valid integer userId from event identifiers", {
            eventId: event.id,
            appUserId: event.app_user_id,
            originalAppUserId: event.original_app_user_id,
         });
         return;
      }

      await this.handleRevenueCatEvent(userId, event);
   }

   // ── Private: event processing ─────────────────────────────────────────────

   private async handleRevenueCatEvent(userId: number, event: RevenueCatWebhookEventData): Promise<void> {
      const targetPlanId = await this.resolveTargetPlanId(event);
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      const processed = await this.subscriptionWebhookRepository.processWebhookEvent({
         userId,
         event,
         targetPlanId,
         freePlanId: freePlan?.id,
         freePlanDurationDays: FREE_PLAN_DURATION_DAYS,
         defaultSubscriptionDurationDays: DEFAULT_SUBSCRIPTION_DURATION_DAYS,
         buildFeatureFullPayload: (plan) => this.buildFeatureFullPayload(this.enrichPlan(plan)),
         buildFeatureLimitsOnlyPayload: (plan) => this.buildFeatureLimitsOnlyPayload(this.enrichPlan(plan)),
      });

      // Email & Push notification logic — all lifecycle events covered
      if (processed) {
         try {
            const user = await this.userRepository.findById(userId);
            const userName = user?.profile?.name || undefined;
            let planName = "your plan";
            if (targetPlanId) {
               const plan = await this.subscriptionPlanRepository.getPlanById(targetPlanId);
               if (plan) planName = plan.name;
            } else if (!targetPlanId) {
               // For events without a target plan (e.g. cancellation of current plan), get current plan name
               const sub = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);
               if (sub?.plan) planName = sub.plan.name;
            }

            if (user?.email) {
               switch (event.type) {
                  case RevenueCatWebhookEvent.INITIAL_PURCHASE:
                     await this.emailService.sendSubscriptionSuccessEmail(user.email, planName, userName);
                     if ((event.price ?? 0) > 0) {
                        await this.emailService.sendPaymentReceiptEmail(user.email, planName, event.price!, event.currency ?? "INR", userName);
                     }
                     break;

                  case RevenueCatWebhookEvent.RENEWAL:
                     if (event.expiration_at_ms) {
                        const renewedUntil = new Date(event.expiration_at_ms).toLocaleDateString("en-IN", { year: "numeric", month: "long", day: "numeric" });
                        await this.emailService.sendSubscriptionRenewalEmail(user.email, planName, renewedUntil, userName);
                     }
                     if ((event.price ?? 0) > 0) {
                        await this.emailService.sendPaymentReceiptEmail(user.email, planName, event.price!, event.currency ?? "INR", userName);
                     }
                     break;

                  case RevenueCatWebhookEvent.CANCELLATION: {
                     const expiresAt = event.expiration_at_ms
                        ? new Date(event.expiration_at_ms).toLocaleDateString("en-IN", { year: "numeric", month: "long", day: "numeric" })
                        : "end of billing period";
                     await this.emailService.sendSubscriptionCancelledEmail(user.email, planName, expiresAt, userName);
                     break;
                  }

                  case RevenueCatWebhookEvent.UNCANCELLATION:
                     await this.emailService.sendSubscriptionRestoredEmail(user.email, planName, userName);
                     break;

                  case RevenueCatWebhookEvent.EXPIRATION:
                     await this.emailService.sendSubscriptionExpiredEmail(user.email, planName, userName);
                     break;

                  case RevenueCatWebhookEvent.BILLING_ISSUE:
                     await this.emailService.sendSubscriptionFailureEmail(user.email, planName, userName);
                     break;

                  default:
                     break;
               }
            }

            // Dispatch Push Notifications
            switch (event.type) {
               case RevenueCatWebhookEvent.INITIAL_PURCHASE:
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.SUBSCRIPTION_SUCCESS,
                     title: "Subscription Activated! ⭐",
                     body: `Welcome to ${planName}! Enjoy your premium privileges.`,
                     data: { type: NotificationType.SUBSCRIPTION_SUCCESS, planName },
                  });
                  break;

               case RevenueCatWebhookEvent.RENEWAL:
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.SUBSCRIPTION_SUCCESS,
                     title: "Subscription Renewed",
                     body: `Your ${planName} subscription has been renewed successfully.`,
                     data: { type: NotificationType.SUBSCRIPTION_SUCCESS, planName },
                  });
                  break;

               case RevenueCatWebhookEvent.CANCELLATION: {
                  const expiresAt = event.expiration_at_ms
                     ? new Date(event.expiration_at_ms).toLocaleDateString("en-IN", { year: "numeric", month: "long", day: "numeric" })
                     : "end of billing period";
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.SUBSCRIPTION_EXPIRING,
                     title: "Subscription Cancelled",
                     body: `Your ${planName} subscription will end on ${expiresAt}.`,
                     data: { type: NotificationType.SUBSCRIPTION_EXPIRING, planName },
                  });
                  break;
               }

               case RevenueCatWebhookEvent.UNCANCELLATION:
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.SUBSCRIPTION_SUCCESS,
                     title: "Subscription Restored",
                     body: `Your ${planName} subscription auto-renewal has been restored.`,
                     data: { type: NotificationType.SUBSCRIPTION_SUCCESS, planName },
                  });
                  break;

               case RevenueCatWebhookEvent.EXPIRATION:
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.SUBSCRIPTION_EXPIRING,
                     title: "Subscription Expired",
                     body: `Your ${planName} subscription has expired. Renew now to unlock premium features!`,
                     data: { type: NotificationType.SUBSCRIPTION_EXPIRING, planName },
                  });
                  break;

               case RevenueCatWebhookEvent.BILLING_ISSUE:
                  await notificationService.sendToUser({
                     userId,
                     type: NotificationType.PAYMENT_FAILED,
                     title: "Payment Issue ⚠️",
                     body: `There was an issue processing your subscription payment for ${planName}. Please update your payment method.`,
                     data: { type: NotificationType.PAYMENT_FAILED, planName },
                  });
                  break;

               default:
                  break;
            }
         } catch (error) {
            logger.error(`Failed to dispatch notifications for event ${event.type} to user ${userId}`, { error });
         }
      }

      // If the event wasn't processed due to a missing targetPlanId, fallback to sync
      if (!processed && !targetPlanId && [RevenueCatWebhookEvent.INITIAL_PURCHASE, RevenueCatWebhookEvent.RENEWAL, RevenueCatWebhookEvent.UNCANCELLATION, RevenueCatWebhookEvent.PRODUCT_CHANGE].includes(event.type)) {
         await this.syncSubscription(userId);
      }
   }

   private async resolveTargetPlanId(event: RevenueCatWebhookEventData): Promise<number | null> {
      const identifier = event.product_id;
      if (identifier) {
         const plan = await this.subscriptionPlanRepository.findPlanByStoreProductId(identifier);
         if (plan) return plan.id;
      }
      return null;
   }

   private async applyFeaturesForPlan(userId: number, plan: EnrichedSubscriptionPlan, resetUsage: boolean): Promise<void> {
      const featurePayload = resetUsage ? this.buildFeatureFullPayload(plan) : this.buildFeatureLimitsOnlyPayload(plan);

      const existingUserFeature = await this.userFeatureRepository.findByUserId(userId);

      if (existingUserFeature) {
         await this.userFeatureRepository.update(userId, featurePayload);
         return;
      }

      await this.userFeatureRepository.create({
         user: { connect: { id: userId } },
         ...this.buildFeatureFullPayload(plan),
      });
   }

   /**
    * Builds a full feature payload including usage counters set to zero.
    * Use only for INITIAL_PURCHASE or downgrade/expiration events (C-8).
    */
   private buildFeatureFullPayload(plan: EnrichedSubscriptionPlan): FeatureFullPayload {
      const limits = this.parsePlanLimits(plan);
      return {
         ...limits,
         interests: 0,
         videoCallMinutes: 0,
         audioCallMinutes: 0,
         messages: 0,
      };
   }

   /**
    * Builds a limits-only feature payload that does NOT include usage counters.
    * Prisma partial update means existing usage values are preserved in the DB.
    * Use for RENEWAL, PRODUCT_CHANGE, CANCELLATION events (C-8).
    */
   private buildFeatureLimitsOnlyPayload(plan: EnrichedSubscriptionPlan): FeatureLimitsOnlyPayload {
      return this.parsePlanLimits(plan);
   }

   private parsePlanLimits(plan: EnrichedSubscriptionPlan): FeatureLimitsOnlyPayload {
      const limits: FeatureLimitsOnlyPayload = {
         isProfileBlurEnabled: false,
         maxInterests: 0,
         maxVideoCallMinutes: 0,
         maxAudioCallMinutes: 0,
         maxMessages: 0,
      };

      for (const planFeature of plan.features) {
         const featureKey = planFeature.featureKey as FeatureKey;
         switch (featureKey) {
            case FeatureKey.PROFILE_BLUR:
               limits.isProfileBlurEnabled = planFeature.limit === "true";
               break;
            case FeatureKey.MAX_INTERESTS:
               limits.maxInterests = this.parseFeatureLimit(planFeature.limit);
               break;
            case FeatureKey.MAX_VIDEO_CALL_MINUTES:
               limits.maxVideoCallMinutes = this.parseFeatureLimit(planFeature.limit);
               break;
            case FeatureKey.MAX_AUDIO_CALL_MINUTES:
               limits.maxAudioCallMinutes = this.parseFeatureLimit(planFeature.limit);
               break;
            case FeatureKey.MAX_MESSAGES:
               limits.maxMessages = this.parseFeatureLimit(planFeature.limit);
               break;
         }
      }

      return limits;
   }

   /**
    * Calls the RevenueCat subscriber API with a 10-second timeout (M-12).
    */
   private async getRevenueCatSubscriberData(userId: number): Promise<RevenueCatSubscriberResponse> {
      const apiKey = env.REVENUECAT_SECRET_API_KEY;

      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), REVENUECAT_API_TIMEOUT_MS);

      let response: Response;
      try {
         response = await fetch(`https://api.revenuecat.com/v1/subscribers/${userId}`, {
            method: "GET",
            headers: {
               Authorization: `Bearer ${apiKey}`,
               "Content-Type": "application/json",
            },
            signal: controller.signal,
         });
      } catch (err: unknown) {
         if (err instanceof Error && err.name === "AbortError") {
            throw new ApiError(504, "RevenueCat API request timed out");
         }
         throw err;
      } finally {
         clearTimeout(timeoutId);
      }

      if (!response.ok) {
         throw new ApiError(response.status, `Failed to retrieve subscriber info from RevenueCat: ${response.statusText}`);
      }

      const data = (await response.json()) as RevenueCatSubscriberResponse;
      logger.info(`[REVENUECAT_API] Fetched subscriber data for userId ${userId}: ${JSON.stringify(data)}`);

      if (!data.subscriber) {
         throw new ApiError(500, "Subscriber data not found in RevenueCat response");
      }

      return data;
   }

   private findActiveRevenueCatProduct(data: RevenueCatSubscriberResponse): {
      productIdentifier: string;
      expiryTime: Date | null;
      willRenew: boolean;
   } | null {
      const subscriptions = data.subscriber?.subscriptions ?? {};
      logger.info(`[REVENUECAT_API] Subscriptions object entries: ${JSON.stringify(subscriptions)}`);

      for (const [productIdentifier, subscription] of Object.entries(subscriptions)) {
         const expiryTime = subscription.expires_date ? new Date(subscription.expires_date) : null;
         const isExpired = expiryTime ? expiryTime <= new Date() : false;

         logger.info(`[REVENUECAT_API] Evaluating product '${productIdentifier}': expires_date=${subscription.expires_date}, expiryTime=${expiryTime?.toISOString()}, isExpired=${isExpired}, unsubscribe_detected_at=${subscription.unsubscribe_detected_at}`);

         if (isExpired) {
            continue;
         }

         const result = {
            productIdentifier,
            expiryTime,
            willRenew: !subscription.unsubscribe_detected_at,
         };
         logger.info(`[REVENUECAT_API] Active product selected: ${JSON.stringify(result)}`);
         return result;
      }

      logger.warn(`[REVENUECAT_API] No active product found among ${Object.keys(subscriptions).length} subscriptions.`);
      return null;
   }

   private async downgradeToFreePlan(userId: number): Promise<EnrichedUserSubscription | null> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         throw new ApiError(500, "FREE plan not found in database");
      }

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const startDate = new Date();
      const endDate = this.addDays(startDate, FREE_PLAN_DURATION_DAYS); // M-6

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: freePlan.id } },
         status: SubscriptionStatus.ACTIVE,
         startDate,
         endDate,
         willRenew: false,
      });

      await this.applyFeaturesForPlan(userId, subscription.plan, true /* resetUsage */);

      return this.enrichUserSubscription(subscription);
   }

   private async activatePlan(userId: number, planId: number, endDate: Date, willRenew: boolean, resetUsage: boolean): Promise<void> {
      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: SubscriptionStatus.ACTIVE,
         startDate: new Date(),
         endDate,
         willRenew,
      });

      await this.applyFeaturesForPlan(userId, subscription.plan, resetUsage);
   }

   private async syncActivatePlan(ctx: ISyncTransactionContext, userId: number, planId: number, endDate: Date, willRenew: boolean, resetUsage: boolean, status: SubscriptionStatus = SubscriptionStatus.ACTIVE): Promise<void> {
      await ctx.deactivateUserSubscriptions(userId);

      // RC-1 fix: store lastEventTimestampMs
      const subscription = await ctx.createUserSubscription({
         userId,
         planId,
         status,
         startDate: new Date(),
         endDate,
         willRenew,
         lastEventTimestampMs: BigInt(Date.now()),
      } as any);

      await this.applyFeaturesInTx(ctx, userId, this.enrichPlan(subscription.plan), resetUsage);
   }

   private async syncDowngradeToFree(ctx: ISyncTransactionContext, userId: number, freePlanId?: number): Promise<void> {
      if (!freePlanId) {
         throw new ApiError(500, "FREE plan not found in database");
      }

      const currentSub = await ctx.findActiveSubscriptionByUserId(userId);
      await ctx.deactivateUserSubscriptions(userId);

      const subscription = await ctx.createUserSubscription({
         userId,
         planId: freePlanId,
         status: SubscriptionStatus.ACTIVE,
         startDate: new Date(),
         endDate: this.addDays(new Date(), FREE_PLAN_DURATION_DAYS),
         willRenew: false,
         lastEventTimestampMs: BigInt(Date.now()), // RC-1 fix
      } as any);

      await this.writeSyncAuditLog(ctx, {
         userId,
         previousPlanId: currentSub?.planId ?? null,
         newPlanId: freePlanId,
         previousStatus: currentSub?.status ?? undefined,
         newStatus: "ACTIVE",
         reason: "Downgraded to FREE plan via /sync",
         source: "SYNC",
      });

      await this.applyFeaturesInTx(ctx, userId, this.enrichPlan(subscription.plan), true);
   }

   private async applyFeaturesInTx(ctx: ISyncTransactionContext, userId: number, plan: EnrichedSubscriptionPlan, resetUsage: boolean): Promise<void> {
      const featurePayload = resetUsage ? this.buildFeatureFullPayload(plan) : this.buildFeatureLimitsOnlyPayload(plan);

      await ctx.applyFeatures(userId, featurePayload);
   }

   private async writeSyncAuditLog(
      ctx: ISyncTransactionContext,
      params: {
         userId: number;
         previousPlanId?: number | null;
         newPlanId?: number | null;
         previousStatus?: string;
         newStatus: string;
         reason: string;
         source: string;
         eventType?: string;
         eventId?: string;
         productId?: string;
         originalTransactionId?: string;
         store?: string;
         environment?: string;
         eventTimestampMs?: bigint | number;
      }
   ): Promise<void> {
      try {
         await ctx.writeAuditLog(params);
      } catch (err: unknown) {
         logger.error("Failed to write audit log entry during sync", { userId: params.userId, err });
      }
   }

   private async getRequiredActivePlan(planId: number): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.subscriptionPlanRepository.getPlanById(planId);

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found");
      }

      if (!plan.isActive) {
         throw new ApiError(400, "This subscription plan is no longer active");
      }

      return this.enrichPlan(plan);
   }

   private async buildSubscriptionMessage(subscription: EnrichedUserSubscription): Promise<string> {
      const endDate = new Date(subscription.endDate).toLocaleDateString();

      if (subscription.status === SubscriptionStatus.EXPIRED || subscription.status === SubscriptionStatus.INACTIVE) {
         return "Your subscription is currently inactive.";
      }

      if (subscription.status === SubscriptionStatus.BILLING_ISSUE) {
         return `Payment failed for your ${subscription.plan?.name ?? "premium"} plan. Please update your payment method to avoid losing access.`;
      }

      if (subscription.status === SubscriptionStatus.GRACE_PERIOD) {
         return `Your subscription has expired. Premium access is temporarily extended — please resubscribe to maintain full access.`;
      }

      if (subscription.nextPlanId) {
         const nextPlan = await this.subscriptionPlanRepository.getPlanById(subscription.nextPlanId);

         if (!nextPlan) {
            return `Your plan will change on ${endDate}`;
         }

         const currentPrice = subscription.plan?.price ?? 0;
         const action = nextPlan.price < currentPrice ? "downgrade" : "change";

         return `Your plan will ${action} to ${nextPlan.name} on ${endDate}`;
      }

      if (!subscription.willRenew || subscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY || subscription.status === SubscriptionStatus.CANCELLED) {
         return `Your plan has been cancelled and will expire on ${endDate}`;
      }

      return `Your plan is active and will renew on ${endDate}`;
   }

   private enrichUserSubscription(subscription: EnrichedUserSubscription): EnrichedUserSubscription {
      const now = new Date();
      const isExpired = subscription.endDate ? new Date(subscription.endDate) < now : false;
      const isGracePeriod = subscription.status === SubscriptionStatus.GRACE_PERIOD;
      const isPaymentFailed = subscription.status === SubscriptionStatus.BILLING_ISSUE;
      const isDowngradeScheduled = subscription.nextPlanId !== null;
      const isCancelled = subscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY || subscription.status === SubscriptionStatus.CANCELLED;

      return {
         ...subscription,
         plan: this.enrichPlan(subscription.plan),
         isExpired,
         isGracePeriod,
         isPaymentFailed,
         isDowngradeScheduled,
         isCancelled,
      };
   }

   private enrichPlan(plan: SubscriptionPlan & { features?: EnrichedPlanFeature[] }): EnrichedSubscriptionPlan {
      const features = plan.features || [];
      return {
         ...plan,
         features: features.map((planFeature) => {
            const feature = SYSTEM_FEATURES.find((systemFeature) => systemFeature.key === planFeature.featureKey);
            return {
               ...planFeature,
               description: planFeature.description || feature?.description || null,
               feature,
            };
         }),
      };
   }

   private sortPlans(plans: EnrichedSubscriptionPlan[]): EnrichedSubscriptionPlan[] {
      return [...plans].sort((firstPlan, secondPlan) => {
         if (firstPlan.name === FREE_PLAN_NAME) return -1;
         if (secondPlan.name === FREE_PLAN_NAME) return 1;
         return firstPlan.price - secondPlan.price;
      });
   }

   private isSubscriptionExpired(endDate: Date): boolean {
      return new Date() > endDate;
   }

   private addDays(date: Date, days: number): Date {
      return new Date(date.getTime() + days * MS_PER_DAY);
   }

   private parseFeatureLimit(value: string): number {
      const parsedValue = Number.parseInt(value, 10);
      return Number.isNaN(parsedValue) ? 0 : parsedValue;
   }
}
