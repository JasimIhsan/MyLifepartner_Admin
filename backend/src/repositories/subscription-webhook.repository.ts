import prisma from "@/config/prisma";
import { Prisma, SubscriptionStatus as PrismaSubscriptionStatus } from "@prisma/client";
import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { 
   ISubscriptionWebhookRepository, 
   ProcessWebhookParams 
} from "@/interfaces/repositories/subscription-webhook.repository.interface";
import logger from "@/utils/logger";

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Grace period after EXPIRATION before the user is downgraded to FREE.
 * Matches the Google Play / Apple store billing grace period (7 days).
 * During this window the reconciliation job will re-check RC state before
 * performing any destructive downgrade.
 */
const EXPIRATION_GRACE_PERIOD_DAYS = 7;

function addDays(date: Date, days: number): Date {
   return new Date(date.getTime() + days * MS_PER_DAY);
}

/**
 * Returns true when the error is a Prisma unique-constraint violation (P2002).
 * Used to detect duplicate event insertion atomically.
 */
function isPrismaUniqueConstraintError(error: unknown): boolean {
   return error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002";
}

/**
 * Builds a structured audit-log data object, including store/environment
 * context for full traceability on every subscription state change.
 */
function buildAuditLogData(params: {
   userId: number;
   previousPlanId: number | null | undefined;
   newPlanId: number | null | undefined;
   previousStatus: string | null | undefined;
   newStatus: string;
   reason: string;
   source: string;
   eventType?: string;
   eventId?: string;
   productId?: string | null;
   originalTransactionId?: string | null;
   store?: string | null;
   environment?: string | null;
   eventTimestampMs?: number | null;
}) {
   return {
      userId: params.userId,
      previousPlanId: params.previousPlanId ?? null,
      newPlanId: params.newPlanId ?? null,
      previousStatus: params.previousStatus ?? null,
      newStatus: params.newStatus,
      reason: params.reason,
      source: params.source,
      eventType: params.eventType ?? null,
      eventId: params.eventId ?? null,
      productId: params.productId ?? null,
      originalTransactionId: params.originalTransactionId ?? null,
      store: params.store ?? null,
      environment: params.environment ?? null,
      eventTimestampMs: params.eventTimestampMs ? BigInt(params.eventTimestampMs) : null,
   };
}

// ─── Downgrade-class event types ────────────────────────────────────────────
const DOWNGRADE_EVENT_TYPES: RevenueCatWebhookEvent[] = [
   RevenueCatWebhookEvent.EXPIRATION,
   RevenueCatWebhookEvent.REFUND,
   RevenueCatWebhookEvent.CANCELLATION,
   RevenueCatWebhookEvent.BILLING_ISSUE,
];

export class SubscriptionWebhookRepository implements ISubscriptionWebhookRepository {
   async processWebhookEvent(params: ProcessWebhookParams): Promise<boolean> {
      const { 
         userId, 
         event, 
         targetPlanId, 
         freePlanId, 
         freePlanDurationDays, 
         defaultSubscriptionDurationDays,
         buildFeatureFullPayload,
         buildFeatureLimitsOnlyPayload 
      } = params;

      let processed = false;

      await prisma.$transaction(async (tx) => {
         // Verify user exists
         const userExists = await tx.user.findUnique({ where: { id: userId }, select: { id: true } });
         if (!userExists) {
            logger.warn("Webhook: resolved userId not found in database — skipping", {
               userId,
               eventId: event.id,
            });
            return;
         }

         // Advisory lock per user to prevent concurrent state corruption
         await tx.$executeRaw`SET LOCAL lock_timeout = '5s'`;
         await tx.$executeRaw`SELECT id FROM \"users\" WHERE id = ${userId} FOR UPDATE`;

         // ─── Idempotency check ──────────────────────────────────────────────────
         // Uses unique constraint on ProcessedRevenueCatEvent.id so duplicate
         // events are rejected atomically even under concurrent delivery.
         try {
            await tx.processedRevenueCatEvent.create({
               data: { id: event.id, type: event.type },
            });
         } catch (insertError: unknown) {
            if (isPrismaUniqueConstraintError(insertError)) {
               logger.info("Webhook: duplicate event — already processed, skipping", {
                  eventId: event.id,
                  type: event.type,
               });
               return; // Skip remaining transaction logic
            }
            throw insertError;
         }

         processed = true; // Event is new and will be processed

         // ─── Load current subscription ──────────────────────────────────────────
         // All four statuses represent users with an active/access-granting subscription.
         const ACTIVE_STATUSES: PrismaSubscriptionStatus[] = [
            PrismaSubscriptionStatus.ACTIVE,
            PrismaSubscriptionStatus.CANCELLED_PENDING_EXPIRY,
            PrismaSubscriptionStatus.BILLING_ISSUE,
            PrismaSubscriptionStatus.GRACE_PERIOD,
         ];

         const currentSubscription = await tx.userSubscription.findFirst({
            where: {
               userId,
               status: { in: ACTIVE_STATUSES },
            },
            include: { plan: { include: { features: true } } },
            orderBy: { createdAt: "desc" },
         });

         // ─── Stale event guard ──────────────────────────────────────────────────
         // Rejects any event whose timestamp is older than the current
         // subscription's last-processed-event timestamp.  This is the single,
         // authoritative guard — the redundant inner guard inside the
         // INITIAL_PURCHASE/RENEWAL branch has been removed.
         if (currentSubscription) {
            const isDowngradeEvent = DOWNGRADE_EVENT_TYPES.includes(event.type);
            const currentTs = currentSubscription.lastEventTimestampMs
               ? Number(currentSubscription.lastEventTimestampMs)
               : null;

            if (currentTs && event.event_timestamp_ms < currentTs) {
               logger.warn("Webhook: ignoring stale event (older than current subscription state)", {
                  eventId: event.id,
                  type: event.type,
                  eventTs: event.event_timestamp_ms,
                  currentTs,
               });
               return;
            } else if (isDowngradeEvent && !currentTs && event.event_timestamp_ms < currentSubscription.createdAt.getTime()) {
               logger.warn("Webhook: stale downgrade event (fallback) ignored", { userId, eventId: event.id });
               return;
            }
         }

         switch (event.type) {

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.INITIAL_PURCHASE:
            case RevenueCatWebhookEvent.RENEWAL:
            case RevenueCatWebhookEvent.PRODUCT_CHANGE: {
               if (!targetPlanId) {
                  logger.warn("Webhook: could not resolve targetPlanId from event product_id — skipping; sync fallback will handle", {
                     eventId: event.id,
                     productId: event.product_id,
                  });
                  // Return false so the caller can fallback to syncSubscription
                  processed = false;
                  return;
               }

               const endDate = event.expiration_at_ms
                  ? new Date(event.expiration_at_ms)
                  : addDays(new Date(), defaultSubscriptionDurationDays);

               // Deferred downgrade: PRODUCT_CHANGE to a lower-priced plan
               if (
                  currentSubscription &&
                  currentSubscription.planId !== targetPlanId &&
                  currentSubscription.planId !== freePlanId &&
                  event.type === RevenueCatWebhookEvent.PRODUCT_CHANGE
               ) {
                  const newPlan = await tx.subscriptionPlan.findUnique({ where: { id: targetPlanId } });
                  if (newPlan && newPlan.price < currentSubscription.plan.price) {
                     await tx.userSubscription.update({
                        where: { id: currentSubscription.id },
                        data: {
                           nextPlanId: targetPlanId,
                           willRenew: false,
                           planChangesAt: endDate,
                           lastEventTimestampMs: event.event_timestamp_ms,
                           revenueCatEventId: event.id,
                        },
                     });
                     await tx.userSubscriptionLog.create({
                        data: buildAuditLogData({
                           userId,
                           previousPlanId: currentSubscription.planId,
                           newPlanId: targetPlanId,
                           previousStatus: currentSubscription.status,
                           newStatus: currentSubscription.status,
                           reason: `Deferred downgrade scheduled via webhook event: ${event.type}`,
                           source: "WEBHOOK",
                           eventType: event.type,
                           eventId: event.id,
                           productId: event.product_id,
                           originalTransactionId: event.original_transaction_id,
                           store: event.store,
                           environment: event.environment,
                           eventTimestampMs: event.event_timestamp_ms,
                        }),
                     });
                     logger.info("Webhook: deferred downgrade scheduled", {
                        userId,
                        eventId: event.id,
                        currentPlanId: currentSubscription.planId,
                        nextPlanId: targetPlanId,
                        planChangesAt: endDate.toISOString(),
                     });
                     return;
                  }
               }

               // Expire previous subscriptions before creating the new one
               // (covers all active-access statuses)
               await tx.userSubscription.updateMany({
                  where: { userId, status: { in: ACTIVE_STATUSES } },
                  data: { status: "EXPIRED" },
               });

               const originalTransactionId = event.original_transaction_id;
               const isInitialPurchase = event.type === RevenueCatWebhookEvent.INITIAL_PURCHASE;

               let subscription;
               if (originalTransactionId) {
                  subscription = await tx.userSubscription.upsert({
                     where: { originalTransactionId },
                     create: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        startDate: new Date(),
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        originalTransactionId,
                        store: event.store,
                        environment: event.environment,
                        billingIssueDetectedAt: null,
                        gracePeriodEndsAt: null,
                     },
                     update: {
                        planId: targetPlanId,
                        status: "ACTIVE",
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        store: event.store,
                        environment: event.environment,
                        billingIssueDetectedAt: null,
                        gracePeriodEndsAt: null,
                     },
                     include: { plan: { include: { features: true } } },
                  });
               } else {
                  subscription = await tx.userSubscription.create({
                     data: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        startDate: new Date(),
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        originalTransactionId: null,
                        store: event.store,
                        environment: event.environment,
                     },
                     include: { plan: { include: { features: true } } },
                  });
               }

               await tx.userSubscriptionLog.create({
                  data: buildAuditLogData({
                     userId,
                     previousPlanId: currentSubscription?.planId,
                     newPlanId: targetPlanId,
                     previousStatus: currentSubscription?.status,
                     newStatus: "ACTIVE",
                     reason: `Subscription activated/renewed via webhook event: ${event.type}`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id,
                     originalTransactionId: originalTransactionId,
                     store: event.store,
                     environment: event.environment,
                     eventTimestampMs: event.event_timestamp_ms,
                  }),
               });

               await tx.transactionHistory.create({
                  data: {
                     userId,
                     planId: targetPlanId,
                     status: "PAID",
                     amount: event.price,
                     currency: event.currency,
                     revenueCatEventId: event.id,
                     originalTransactionId: originalTransactionId ?? null,
                     store: event.store,
                     environment: event.environment,
                  },
               });

               const targetPlan = subscription?.plan || (targetPlanId ? await tx.subscriptionPlan.findUnique({ where: { id: targetPlanId }, include: { features: true } }) : null);

               if (targetPlan) {
                  const featurePayload = isInitialPurchase
                     ? buildFeatureFullPayload(targetPlan)
                     : buildFeatureLimitsOnlyPayload(targetPlan);
                  const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });

                  if (existingFeatures) {
                     await tx.userFeature.update({ where: { userId }, data: featurePayload });
                  } else {
                     await tx.userFeature.create({
                        data: { userId, ...buildFeatureFullPayload(targetPlan) },
                     });
                  }
               }

               logger.info("Webhook: subscription activated/renewed", {
                  userId,
                  eventId: event.id,
                  type: event.type,
                  planId: targetPlanId,
                  endDate: endDate.toISOString(),
                  store: event.store,
                  environment: event.environment,
               });
               break;
            }

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.UNCANCELLATION: {
               const txnId = event.original_transaction_id;
               let subToRestore = currentSubscription;

               if (txnId && currentSubscription?.originalTransactionId !== txnId) {
                  // Search across all active statuses — the UNCANCELLATION may arrive after an
                  // intermediate state transition (e.g., BILLING_ISSUE). Also accept ACTIVE in
                  // case an out-of-order event arrives after a prior RENEWAL already restored it.
                  subToRestore = await tx.userSubscription.findFirst({
                     where: { userId, status: { in: ACTIVE_STATUSES }, originalTransactionId: txnId },
                     orderBy: { createdAt: "desc" },
                     include: { plan: { include: { features: true } } },
                  }) || currentSubscription;
               }

               if (subToRestore && subToRestore.status === "CANCELLED_PENDING_EXPIRY") {
                  await tx.userSubscription.update({
                     where: { id: subToRestore.id },
                     data: {
                        status: "ACTIVE",
                        willRenew: true,
                        cancelledAt: null,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        revenueCatEventId: event.id,
                     },
                  });
                  await tx.userSubscriptionLog.create({
                     data: buildAuditLogData({
                        userId,
                        previousPlanId: subToRestore.planId,
                        newPlanId: subToRestore.planId,
                        previousStatus: "CANCELLED_PENDING_EXPIRY",
                        newStatus: "ACTIVE",
                        reason: `Subscription un-cancelled (auto-renew restored) via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id,
                        originalTransactionId: event.original_transaction_id,
                        store: event.store,
                        environment: event.environment,
                        eventTimestampMs: event.event_timestamp_ms,
                     }),
                  });
                  logger.info("Webhook: uncancellation processed — subscription restored to ACTIVE", {
                     userId,
                     eventId: event.id,
                     subscriptionId: subToRestore.id,
                  });
               } else {
                  logger.warn("Webhook: UNCANCELLATION received but no matching CANCELLED_PENDING_EXPIRY subscription found", {
                     userId,
                     eventId: event.id,
                  });
               }
               break;
            }

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.CANCELLATION: {
               const txnId = event.original_transaction_id;
               let subToCancel = currentSubscription;

               if (txnId && currentSubscription?.originalTransactionId !== txnId) {
                  // CANCELLATION may arrive for a subscription that's now in BILLING_ISSUE state
                  subToCancel = await tx.userSubscription.findFirst({
                     where: { userId, status: { in: ACTIVE_STATUSES }, originalTransactionId: txnId },
                     orderBy: { createdAt: "desc" },
                     include: { plan: { include: { features: true } } },
                  }) || currentSubscription;
               }

               if (subToCancel) {
                  await tx.userSubscription.update({
                     where: { id: subToCancel.id },
                     data: {
                        status: "CANCELLED_PENDING_EXPIRY",
                        willRenew: false,
                        cancelledAt: new Date(),
                        lastEventTimestampMs: event.event_timestamp_ms,
                        revenueCatEventId: event.id,
                     },
                  });
                  await tx.userSubscriptionLog.create({
                     data: buildAuditLogData({
                        userId,
                        previousPlanId: subToCancel.planId,
                        newPlanId: subToCancel.planId,
                        previousStatus: subToCancel.status,
                        newStatus: "CANCELLED_PENDING_EXPIRY",
                        reason: `Subscription cancellation recorded via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id,
                        originalTransactionId: event.original_transaction_id,
                        store: event.store,
                        environment: event.environment,
                        eventTimestampMs: event.event_timestamp_ms,
                     }),
                  });

                  await tx.transactionHistory.create({
                     data: {
                        userId,
                        planId: subToCancel.planId,
                        status: "CANCELLED",
                        amount: event.price,
                        currency: event.currency,
                        revenueCatEventId: event.id,
                        originalTransactionId: event.original_transaction_id ?? null,
                        store: event.store,
                        environment: event.environment,
                     },
                  });
                  logger.info("Webhook: cancellation recorded — premium access preserved until expiry", {
                     userId,
                     eventId: event.id,
                     subscriptionId: subToCancel.id,
                     endDate: subToCancel.endDate.toISOString(),
                  });
               } else {
                  logger.warn("Webhook: CANCELLATION received but no active subscription found", { userId, eventId: event.id });
               }
               break;
            }

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.BILLING_ISSUE: {
               if (currentSubscription) {
                  // Transition to BILLING_ISSUE status — user retains access during
                  // the store's billing grace period while payment is retried.
                  await tx.userSubscription.update({
                     where: { id: currentSubscription.id },
                     data: {
                        status: "BILLING_ISSUE",
                        billingIssueDetectedAt: new Date(),
                        lastEventTimestampMs: event.event_timestamp_ms,
                        revenueCatEventId: event.id,
                     },
                  });
                  await tx.userSubscriptionLog.create({
                     data: buildAuditLogData({
                        userId,
                        previousPlanId: currentSubscription.planId,
                        newPlanId: currentSubscription.planId,
                        previousStatus: currentSubscription.status,
                        newStatus: "BILLING_ISSUE",
                        reason: `Billing issue detected via webhook event: ${event.type}. User retains access during store retry period.`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id,
                        originalTransactionId: event.original_transaction_id,
                        store: event.store,
                        environment: event.environment,
                        eventTimestampMs: event.event_timestamp_ms,
                     }),
                  });

                  await tx.transactionHistory.create({
                     data: {
                        userId,
                        planId: currentSubscription.planId,
                        status: "FAILED",
                        amount: event.price,
                        currency: event.currency,
                        revenueCatEventId: event.id,
                        originalTransactionId: event.original_transaction_id ?? null,
                        store: event.store,
                        environment: event.environment,
                     },
                  });
                  logger.warn("Webhook: billing issue — subscription set to BILLING_ISSUE, access preserved during store grace period", {
                     userId,
                     eventId: event.id,
                     subscriptionId: currentSubscription.id,
                  });
               } else {
                  logger.warn("Webhook: BILLING_ISSUE received but no active subscription found", {
                     userId,
                     eventId: event.id,
                  });
               }
               break;
            }

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.EXPIRATION: {
               // ── Safe EXPIRATION handling ──────────────────────────────────────
               // Instead of an immediate FREE downgrade, we transition to a
               // GRACE_PERIOD status for EXPIRATION_GRACE_PERIOD_DAYS days.
               // This protects users from delayed webhooks, store processing lag,
               // and RevenueCat delivery failures.
               //
               // The reconciliation job will check RC state after grace ends and
               // perform the FREE downgrade only when confirmed expired.
               const txnId = event.original_transaction_id;
               let whereClause: any = {
                  userId,
                  status: { in: ["ACTIVE", "CANCELLED_PENDING_EXPIRY", "BILLING_ISSUE"] },
               };

               if (txnId) {
                  whereClause.originalTransactionId = txnId;
               } else if (targetPlanId) {
                  whereClause.planId = targetPlanId;
               }

               const gracePeriodEndsAt = addDays(new Date(), EXPIRATION_GRACE_PERIOD_DAYS);

               await tx.userSubscription.updateMany({
                  where: whereClause,
                  data: {
                     status: "GRACE_PERIOD",
                     expiredAt: new Date(),
                     gracePeriodEndsAt,
                     lastEventTimestampMs: event.event_timestamp_ms,
                     revenueCatEventId: event.id,
                  },
               });

               await tx.userSubscriptionLog.create({
                  data: buildAuditLogData({
                     userId,
                     previousPlanId: currentSubscription?.planId,
                     newPlanId: currentSubscription?.planId,
                     previousStatus: currentSubscription?.status ?? "ACTIVE",
                     newStatus: "GRACE_PERIOD",
                     reason: `Subscription expired; entered ${EXPIRATION_GRACE_PERIOD_DAYS}-day reconciliation grace period via webhook event: ${event.type}. Reconciliation job will finalize after ${gracePeriodEndsAt.toISOString()}.`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id,
                     originalTransactionId: event.original_transaction_id,
                     store: event.store,
                     environment: event.environment,
                     eventTimestampMs: event.event_timestamp_ms,
                  }),
               });

               logger.info("Webhook: subscription expired — entered GRACE_PERIOD (FREE downgrade deferred to reconciliation job)", {
                  userId,
                  eventId: event.id,
                  gracePeriodEndsAt: gracePeriodEndsAt.toISOString(),
               });
               break;
            }

            // ────────────────────────────────────────────────────────────────────
            case RevenueCatWebhookEvent.REFUND: {
               // Refunds are destructive — immediate action is justified because
               // the store has explicitly reversed the transaction.
               const txnId = event.original_transaction_id;
               let whereClause: any = {
                  userId,
                  status: { in: ACTIVE_STATUSES },
               };

               if (txnId) {
                  whereClause.originalTransactionId = txnId;
               } else if (targetPlanId) {
                  whereClause.planId = targetPlanId;
               }

               await tx.userSubscription.updateMany({
                  where: whereClause,
                  data: {
                     status: "EXPIRED",
                     refundedAt: new Date(),
                     lastEventTimestampMs: event.event_timestamp_ms,
                     revenueCatEventId: event.id,
                  },
               });

               await tx.userSubscriptionLog.create({
                  data: buildAuditLogData({
                     userId,
                     previousPlanId: currentSubscription?.planId,
                     newPlanId: null,
                     previousStatus: currentSubscription?.status ?? "ACTIVE",
                     newStatus: "EXPIRED",
                     reason: `Subscription refunded via webhook event: ${event.type}`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id,
                     originalTransactionId: event.original_transaction_id,
                     store: event.store,
                     environment: event.environment,
                     eventTimestampMs: event.event_timestamp_ms,
                  }),
               });

               await tx.transactionHistory.create({
                  data: {
                     userId,
                     planId: targetPlanId ?? currentSubscription?.planId ?? null,
                     status: "REFUNDED",
                     amount: event.price,
                     currency: event.currency,
                     revenueCatEventId: event.id,
                     originalTransactionId: event.original_transaction_id ?? null,
                     store: event.store,
                     environment: event.environment,
                  },
               });

               // Only downgrade to FREE if no other active subscription exists
               const remaining = await tx.userSubscription.findFirst({
                  where: { userId, status: "ACTIVE" },
               });
               if (!remaining) {
                  if (freePlanId) {
                     const freeSub = await tx.userSubscription.create({
                        data: {
                           userId,
                           planId: freePlanId,
                           status: "ACTIVE",
                           startDate: new Date(),
                           endDate: addDays(new Date(), freePlanDurationDays),
                           willRenew: false,
                           revenueCatEventId: event.id,
                           lastEventTimestampMs: event.event_timestamp_ms,
                           originalTransactionId: null,
                        },
                        include: { plan: { include: { features: true } } },
                     });

                     await tx.userSubscriptionLog.create({
                        data: buildAuditLogData({
                           userId,
                           previousPlanId: currentSubscription?.planId,
                           newPlanId: freePlanId,
                           previousStatus: "EXPIRED",
                           newStatus: "ACTIVE",
                           reason: `Downgraded to FREE plan after refund via webhook event: ${event.type}`,
                           source: "WEBHOOK",
                           eventType: event.type,
                           eventId: event.id,
                           productId: event.product_id,
                           originalTransactionId: event.original_transaction_id,
                           store: event.store,
                           environment: event.environment,
                           eventTimestampMs: event.event_timestamp_ms,
                        }),
                     });

                     const featurePayload = buildFeatureFullPayload(freeSub.plan);
                     const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
                     if (existingFeatures) {
                        await tx.userFeature.update({ where: { userId }, data: featurePayload });
                     } else {
                        await tx.userFeature.create({ data: { userId, ...featurePayload } });
                     }
                  }
               }

               logger.warn("Webhook: subscription refunded — downgraded to FREE", {
                  userId,
                  eventId: event.id,
               });
               break;
            }

            default: {
               logger.warn("Webhook: unhandled event type", { type: event.type, eventId: event.id });
               break;
            }
         }
      }, { maxWait: 5000, timeout: 10000 });

      return processed;
   }
}
