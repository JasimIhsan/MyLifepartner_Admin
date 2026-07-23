import prisma from "@/config/prisma";
import { Prisma } from "@prisma/client";
import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { 
   ISubscriptionWebhookRepository, 
   ProcessWebhookParams 
} from "@/interfaces/repositories/subscription-webhook.repository.interface";
import logger from "@/utils/logger";

const MS_PER_DAY = 24 * 60 * 60 * 1000;

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

         // Idempotency check via unique constraint
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

         const currentSubscription = await tx.userSubscription.findFirst({
            where: { userId, status: "ACTIVE" },
            include: { plan: true },
            orderBy: { createdAt: "desc" },
         });

         // Reject stale events
         if (currentSubscription) {
            const isDowngradeEvent = DOWNGRADE_EVENT_TYPES.includes(event.type);
            const currentTs = currentSubscription.lastEventTimestampMs ? Number(currentSubscription.lastEventTimestampMs) : null;
            
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
            case RevenueCatWebhookEvent.INITIAL_PURCHASE:
            case RevenueCatWebhookEvent.RENEWAL:
            case RevenueCatWebhookEvent.UNCANCELLATION:
            case RevenueCatWebhookEvent.PRODUCT_CHANGE: {
               if (!targetPlanId) {
                  logger.warn("Webhook: could not resolve targetPlanId from event product_id — skipping webhook sync fallback should be handled by caller", {
                     eventId: event.id,
                     productId: event.product_id,
                  });
                  // We return and let the service handle the fallback (e.g. syncSubscription)
                  processed = false; 
                  return;
               }

               const endDate = event.expiration_at_ms ? new Date(event.expiration_at_ms) : addDays(new Date(), defaultSubscriptionDurationDays);

               // Deferred downgrade: PRODUCT_CHANGE to a lower-priced plan
               if (currentSubscription && currentSubscription.planId !== targetPlanId && currentSubscription.planId !== freePlanId && event.type === RevenueCatWebhookEvent.PRODUCT_CHANGE) {
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
                        data: {
                           userId,
                           previousPlanId: currentSubscription.planId,
                           newPlanId: targetPlanId,
                           previousStatus: currentSubscription.status,
                           newStatus: currentSubscription.status,
                           reason: `Deferred downgrade scheduled via webhook event: ${event.type}`,
                           source: "WEBHOOK",
                           eventType: event.type,
                           eventId: event.id,
                           productId: event.product_id ?? null,
                           originalTransactionId: event.original_transaction_id ?? null,
                           eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                        },
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

               // Expire active subscriptions
               await tx.userSubscription.updateMany({
                  where: { userId, status: "ACTIVE" },
                  data: { status: "EXPIRED" },
               });

               const originalTransactionId = event.original_transaction_id;
               // Enhanced stale guard
               if (currentSubscription) {
                  const isDowngradeEvent = DOWNGRADE_EVENT_TYPES.includes(event.type);
                  if (isDowngradeEvent) {
                     if (currentSubscription.lastEventTimestampMs && BigInt(event.event_timestamp_ms) < currentSubscription.lastEventTimestampMs) {
                        logger.warn("Webhook: stale downgrade event ignored", { userId, eventId: event.id });
                        return;
                     } else if (!currentSubscription.lastEventTimestampMs && event.event_timestamp_ms < currentSubscription.createdAt.getTime()) {
                        logger.warn("Webhook: stale downgrade event (fallback) ignored", { userId, eventId: event.id });
                        return;
                     }
                  }
               }

               const isInitialPurchase = event.type === RevenueCatWebhookEvent.INITIAL_PURCHASE;

               const subscription = await tx.userSubscription.create({
                  data: {
                     userId,
                     planId: targetPlanId,
                     status: "ACTIVE",
                     startDate: new Date(),
                     endDate,
                     willRenew: true,
                     revenueCatEventId: event.id,
                     lastEventTimestampMs: event.event_timestamp_ms,
                     originalTransactionId: originalTransactionId ?? null,
                     store: event.store,
                     environment: event.environment,
                  },
                  include: { plan: { include: { features: true } } },
               });

               await tx.userSubscriptionLog.create({
                  data: {
                     userId,
                     previousPlanId: currentSubscription?.planId ?? null,
                     newPlanId: targetPlanId,
                     previousStatus: currentSubscription?.status ?? null,
                     newStatus: "ACTIVE",
                     reason: `Subscription activated/updated via webhook event: ${event.type}`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id ?? null,
                     originalTransactionId: originalTransactionId ?? null,
                     eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                  },
               });

               const featurePayload = isInitialPurchase ? buildFeatureFullPayload(subscription.plan) : buildFeatureLimitsOnlyPayload(subscription.plan);
               const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
               
               if (existingFeatures) {
                  await tx.userFeature.update({ where: { userId }, data: featurePayload });
               } else {
                  await tx.userFeature.create({
                     data: { userId, ...buildFeatureFullPayload(subscription.plan) },
                  });
               }

               logger.info("Webhook: subscription activated", {
                  userId,
                  eventId: event.id,
                  type: event.type,
                  planId: targetPlanId,
                  endDate: endDate.toISOString(),
               });
               break;
            }

            case RevenueCatWebhookEvent.CANCELLATION: {
               if (currentSubscription) {
                  await tx.userSubscription.update({
                     where: { id: currentSubscription.id },
                     data: {
                        willRenew: false,
                        cancelledAt: new Date(),
                        lastEventTimestampMs: event.event_timestamp_ms,
                        revenueCatEventId: event.id,
                     },
                  });
                  await tx.userSubscriptionLog.create({
                     data: {
                        userId,
                        previousPlanId: currentSubscription.planId,
                        newPlanId: currentSubscription.planId,
                        previousStatus: currentSubscription.status,
                        newStatus: currentSubscription.status,
                        reason: `Subscription cancellation recorded via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id ?? null,
                        originalTransactionId: event.original_transaction_id ?? null,
                        eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                     },
                  });
                  logger.info("Webhook: cancellation recorded — access preserved until expiry", {
                     userId,
                     eventId: event.id,
                     endDate: currentSubscription.endDate.toISOString(),
                  });
               }
               break;
            }

            case RevenueCatWebhookEvent.BILLING_ISSUE: {
               if (currentSubscription) {
                  await tx.userSubscription.update({
                     where: { id: currentSubscription.id },
                     data: {
                        billingIssueDetectedAt: new Date(),
                        lastEventTimestampMs: event.event_timestamp_ms,
                        revenueCatEventId: event.id,
                     },
                  });
                  await tx.userSubscriptionLog.create({
                     data: {
                        userId,
                        previousPlanId: currentSubscription.planId,
                        newPlanId: currentSubscription.planId,
                        previousStatus: currentSubscription.status,
                        newStatus: currentSubscription.status,
                        reason: `Billing issue detected via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id ?? null,
                        originalTransactionId: event.original_transaction_id ?? null,
                        eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                     },
                  });
                  logger.warn("Webhook: billing issue detected — access preserved during grace period", {
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

            case RevenueCatWebhookEvent.EXPIRATION: {
               const txnId = event.original_transaction_id;
               const whereClause = txnId
                  ? { userId, status: "ACTIVE" as const, originalTransactionId: txnId }
                  : { userId, status: "ACTIVE" as const };

               await tx.userSubscription.updateMany({
                  where: whereClause,
                  data: { status: "EXPIRED", expiredAt: new Date(), lastEventTimestampMs: event.event_timestamp_ms, revenueCatEventId: event.id },
               });

               await tx.userSubscriptionLog.create({
                  data: {
                     userId,
                     previousPlanId: currentSubscription?.planId ?? null,
                     newPlanId: null,
                     previousStatus: currentSubscription?.status ?? "ACTIVE",
                     newStatus: "EXPIRED",
                     reason: `Subscription expired via webhook event: ${event.type}`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id ?? null,
                     originalTransactionId: event.original_transaction_id ?? null,
                     eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                  },
               });

               const remaining = await tx.userSubscription.findFirst({ where: { userId, status: "ACTIVE" } });
               if (remaining) break;


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
                     data: {
                        userId,
                        previousPlanId: currentSubscription?.planId ?? null,
                        newPlanId: freePlanId,
                        previousStatus: "EXPIRED",
                        newStatus: "ACTIVE",
                        reason: `Downgraded to FREE plan after expiration via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id ?? null,
                        originalTransactionId: event.original_transaction_id ?? null,
                        eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                     },
                  });

                  const featurePayload = buildFeatureFullPayload(freeSub.plan);
                  const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
                  if (existingFeatures) {
                     await tx.userFeature.update({ where: { userId }, data: featurePayload });
                  } else {
                     await tx.userFeature.create({ data: { userId, ...featurePayload } });
                  }
               }

               logger.info("Webhook: subscription expired — downgraded to FREE", {
                  userId,
                  eventId: event.id,
               });
               break;
            }

            case RevenueCatWebhookEvent.REFUND: {
               const txnId = event.original_transaction_id;
               const whereClause = txnId
                  ? { userId, status: "ACTIVE" as const, originalTransactionId: txnId }
                  : { userId, status: "ACTIVE" as const };

               await tx.userSubscription.updateMany({
                  where: whereClause,
                  data: { status: "EXPIRED", refundedAt: new Date(), lastEventTimestampMs: event.event_timestamp_ms, revenueCatEventId: event.id },
               });

               await tx.userSubscriptionLog.create({
                  data: {
                     userId,
                     previousPlanId: currentSubscription?.planId ?? null,
                     newPlanId: null,
                     previousStatus: currentSubscription?.status ?? "ACTIVE",
                     newStatus: "EXPIRED",
                     reason: `Subscription refunded via webhook event: ${event.type}`,
                     source: "WEBHOOK",
                     eventType: event.type,
                     eventId: event.id,
                     productId: event.product_id ?? null,
                     originalTransactionId: event.original_transaction_id ?? null,
                     eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                  },
               });

               const remaining = await tx.userSubscription.findFirst({ where: { userId, status: "ACTIVE" } });
               if (remaining) break;


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
                     data: {
                        userId,
                        previousPlanId: currentSubscription?.planId ?? null,
                        newPlanId: freePlanId,
                        previousStatus: "EXPIRED",
                        newStatus: "ACTIVE",
                        reason: `Downgraded to FREE plan after refund via webhook event: ${event.type}`,
                        source: "WEBHOOK",
                        eventType: event.type,
                        eventId: event.id,
                        productId: event.product_id ?? null,
                        originalTransactionId: event.original_transaction_id ?? null,
                        eventTimestampMs: event.event_timestamp_ms ? BigInt(event.event_timestamp_ms) : null,
                     },
                  });

                  const featurePayload = buildFeatureFullPayload(freeSub.plan);
                  const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
                  if (existingFeatures) {
                     await tx.userFeature.update({ where: { userId }, data: featurePayload });
                  } else {
                     await tx.userFeature.create({ data: { userId, ...featurePayload } });
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
