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
import { EnrichedPlanFeature, EnrichedSubscriptionPlan, EnrichedUserSubscription, IUserSubscriptionService, SubscriptionPlan } from "@/interfaces/services/user.subscription.service.interface";
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
const PURCHASE_SYNC_GRACE_PERIOD_MS = 2 * 60 * 1000; // 2 minutes
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

   async syncSubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      logger.info(`[SYNC_SUBSCRIPTION] Starting sync for userId: ${userId}`);
      const revenueCatData = await this.getRevenueCatSubscriberData(userId);

      const originalUserIdStr = revenueCatData.subscriber?.original_app_user_id;

      logger.info(`[SYNC_SUBSCRIPTION] Identity check passed inherently by RevenueCat API. Fetched data for userId ${userId}. (original_app_user_id: '${originalUserIdStr}')`);

      const activeProduct = this.findActiveRevenueCatProduct(revenueCatData);

      let emailPlan: SubscriptionPlan | null = null;

      await this.userSubscriptionRepository.executeSyncTransaction(userId, async (ctx) => {
         const currentSubscription = await ctx.findActiveSubscriptionByUserId(userId);
         const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

         logger.info(`[SYNC_SUBSCRIPTION] activeProduct: ${JSON.stringify(activeProduct)}, currentSubscription planId: ${currentSubscription?.planId}, freePlan id: ${freePlan?.id}`);

         if (!activeProduct) {
            // RC-3 fix: grace period applies to ALL users
            if (currentSubscription) {
               const timeSinceCreated = new Date().getTime() - currentSubscription.createdAt.getTime();
               logger.warn(`[SYNC_SUBSCRIPTION] No active product in RevenueCat for userId ${userId}. currentSubscription planId=${currentSubscription.planId}, timeSinceCreatedMs=${timeSinceCreated}, gracePeriodMs=${PURCHASE_SYNC_GRACE_PERIOD_MS}`);

               if (timeSinceCreated < PURCHASE_SYNC_GRACE_PERIOD_MS) {
                  logger.info(`[SYNC_SUBSCRIPTION] Within purchase sync grace period (${timeSinceCreated}ms < ${PURCHASE_SYNC_GRACE_PERIOD_MS}ms). Retaining current subscription.`);
                  return;
               }

               if (currentSubscription.planId === freePlan?.id) {
                  logger.info(`[SYNC_SUBSCRIPTION] No active product and user is already on FREE plan. Nothing to do.`);
                  return;
               }
            }
            logger.warn(`[SYNC_SUBSCRIPTION] Triggering downgradeToFreePlan for userId ${userId} because activeProduct is null.`);
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
            emailPlan = targetPlan;
            return;
         }

         if (currentSubscription.planId === targetPlan.id) {
            let finalStatus = targetStatus;
            let finalWillRenew = activeProduct.willRenew;

            // C-9 fix: Prevent stale RevenueCat REST API from overwriting a webhook cancellation
            if (currentSubscription.status === SubscriptionStatus.CANCELLED_PENDING_EXPIRY && targetStatus === SubscriptionStatus.ACTIVE) {
               logger.warn(`[SYNC_SUBSCRIPTION] DB shows CANCELLED_PENDING_EXPIRY but RevenueCat API shows ACTIVE. Trusting DB/Webhook to prevent stale cache overwrite.`);
               finalStatus = SubscriptionStatus.CANCELLED_PENDING_EXPIRY;
               finalWillRenew = false;
            }

            logger.info(`[SYNC_SUBSCRIPTION] Updating existing plan ${targetPlan.name} (id: ${targetPlan.id}) for userId ${userId}. endDate=${endDate.toISOString()}, willRenew=${finalWillRenew}, status=${finalStatus}`);
            await ctx.updateUserSubscription(currentSubscription.id, {
               endDate,
               willRenew: finalWillRenew,
               status: finalStatus as unknown as any,
               nextPlanId: null,
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
            emailPlan = targetPlan;
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

      const finalEmailPlan = emailPlan as SubscriptionPlan | null;
      if (finalEmailPlan) {
         try {
            const user = await this.userRepository.findById(userId);
            if (user && user.email) {
               await this.emailService.sendPaymentReceiptEmail(user.email, finalEmailPlan.name, finalEmailPlan.price, user.profile?.name || undefined);
            }
         } catch (error) {
            logger.error(`[SYNC_SUBSCRIPTION] Failed to send subscription email to userId ${userId}`, { error });
         }
      }

      return this.getMySubscription(userId);
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

      // Email notification logic
      if (processed) {
         try {
            const user = await this.userRepository.findById(userId);
            if (user && user.email) {
               let planName = "your plan";
               if (targetPlanId) {
                  const plan = await this.subscriptionPlanRepository.getPlanById(targetPlanId);
                  if (plan) planName = plan.name;
               }

               if (event.type === RevenueCatWebhookEvent.INITIAL_PURCHASE) {
                  await this.emailService.sendSubscriptionSuccessEmail(user.email, planName, user.profile?.name || undefined);
               } else if (event.type === RevenueCatWebhookEvent.RENEWAL) {
                  const expirationDate = new Date(event.expiration_at_ms || Date.now() + 30 * 24 * 60 * 60 * 1000).toLocaleDateString();
                  await this.emailService.sendSubscriptionRenewalEmail(user.email, planName, expirationDate, user.profile?.name || undefined);
               } else if (event.type === RevenueCatWebhookEvent.BILLING_ISSUE) {
                  await this.emailService.sendSubscriptionFailureEmail(user.email, planName, user.profile?.name || undefined);
               }
            }
         } catch (error) {
            logger.error(`Failed to send subscription email for event ${event.type} to user ${userId}`, { error });
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
      return {
         ...subscription,
         plan: this.enrichPlan(subscription.plan),
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
