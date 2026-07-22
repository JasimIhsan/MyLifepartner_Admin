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
         await tx.$executeRaw`SELECT pg_advisory_xact_lock(${userId})`;

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
         if (currentSubscription?.lastEventTimestampMs && event.event_timestamp_ms < Number(currentSubscription.lastEventTimestampMs)) {
            logger.warn("Webhook: ignoring stale event (older than current subscription state)", {
               eventId: event.id,
               type: event.type,
               eventTs: event.event_timestamp_ms,
               currentTs: Number(currentSubscription.lastEventTimestampMs),
            });
            return;
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
                     },
                     update: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        store: event.store,
                        environment: event.environment,
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
               await tx.userSubscription.updateMany({
                  where: { userId, status: "ACTIVE" },
                  data: { status: "EXPIRED", expiredAt: new Date() },
               });

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
               await tx.userSubscription.updateMany({
                  where: { userId, status: "ACTIVE" },
                  data: { status: "EXPIRED", refundedAt: new Date() },
               });

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
      });

      return processed;
   }
}
