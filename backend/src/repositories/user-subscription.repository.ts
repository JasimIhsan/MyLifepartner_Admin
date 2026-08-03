import prisma from "@/config/prisma";
import { ISyncTransactionContext, IUserSubscriptionRepository, SubscriptionStatus, UserSubscriptionWithPlan } from "@/interfaces/repositories/user-subscription.repository.interface";
import { Prisma, SubscriptionStatus as PrismaSubscriptionStatus } from "@prisma/client";

const userSubscriptionIncludePlanAndFeatures = {
   plan: {
      include: {
         features: true,
      },
   },
} satisfies Prisma.UserSubscriptionInclude;

/**
 * All statuses that represent a user with an "active" subscription.
 * BILLING_ISSUE and GRACE_PERIOD users still have access — they must be
 * included so /my-subscription returns their subscription and so that a new
 * purchase correctly expires/replaces the old record.
 */
const ACTIVE_STATUSES: PrismaSubscriptionStatus[] = [
   PrismaSubscriptionStatus.ACTIVE,
   PrismaSubscriptionStatus.CANCELLED_PENDING_EXPIRY,
   PrismaSubscriptionStatus.BILLING_ISSUE,
   PrismaSubscriptionStatus.GRACE_PERIOD,
];

export class UserSubscriptionRepository implements IUserSubscriptionRepository {
   /**
    * Creates a user subscription.
    *
    * @param data - User subscription creation data.
    * @returns Created user subscription with plan and features.
    */
   async createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<UserSubscriptionWithPlan> {
      return prisma.userSubscription.create({
         data,
         include: userSubscriptionIncludePlanAndFeatures,
      }) as Promise<UserSubscriptionWithPlan>;
   }

   /**
    * Finds the active subscription of a user.
    *
    * Considers ACTIVE, CANCELLED_PENDING_EXPIRY, BILLING_ISSUE, and
    * GRACE_PERIOD as "active" — all of these states grant the user access.
    *
    * @param userId - User ID.
    * @returns Active user subscription with plan and features, or null if not found.
    */
   async findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null> {
      return prisma.userSubscription.findFirst({
         where: {
            userId,
            status: { in: ACTIVE_STATUSES },
         },
         include: userSubscriptionIncludePlanAndFeatures,
         orderBy: {
            createdAt: "desc",
         },
      }) as Promise<UserSubscriptionWithPlan | null>;
   }

   /**
    * Deactivates ALL active subscriptions of a user (marks them as EXPIRED).
    * Covers ACTIVE, CANCELLED_PENDING_EXPIRY, BILLING_ISSUE, and GRACE_PERIOD
    * so that a new purchase always starts from a clean state.
    *
    * @param userId - User ID.
    * @returns Prisma batch update result.
    */
   async deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload> {
      return prisma.userSubscription.updateMany({
         where: {
            userId,
            status: { in: ACTIVE_STATUSES },
         },
         data: {
            status: SubscriptionStatus.EXPIRED as unknown as PrismaSubscriptionStatus,
         },
      });
   }

   /**
    * Updates a user subscription.
    *
    * @param id - User subscription ID.
    * @param data - User subscription update data.
    * @returns Updated user subscription with plan and features.
    */
   async updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<UserSubscriptionWithPlan> {
      return prisma.userSubscription.update({
         where: {
            id,
         },
         data,
         include: userSubscriptionIncludePlanAndFeatures,
      }) as Promise<UserSubscriptionWithPlan>;
   }

   /**
    * Executes an operation inside a transaction with a user row-level lock.
    * This encapsulates Prisma logic entirely so services do not depend on Prisma directly.
    */
   async executeSyncTransaction<T>(userId: number, operation: (ctx: ISyncTransactionContext) => Promise<T>): Promise<T> {
      return prisma.$transaction(
         async (tx) => {
            // Set lock timeout to 5 seconds to prevent deadlocks from exhausting connections
            await tx.$executeRaw`SET LOCAL lock_timeout = '5s'`;

            // Acquire a per-user row-level lock to prevent concurrent state corruption
            await tx.$executeRaw`SELECT id FROM "users" WHERE id = ${userId} FOR UPDATE`;

            const ctx: ISyncTransactionContext = {
               findActiveSubscriptionByUserId: async (uid: number) => {
                  return tx.userSubscription.findFirst({
                     where: { userId: uid, status: { in: ACTIVE_STATUSES } },
                     include: userSubscriptionIncludePlanAndFeatures,
                     orderBy: { createdAt: "desc" },
                  }) as Promise<UserSubscriptionWithPlan | null>;
               },
               deactivateUserSubscriptions: async (uid: number) => {
                  await tx.userSubscription.updateMany({
                     where: { userId: uid, status: { in: ACTIVE_STATUSES } },
                     data: { status: PrismaSubscriptionStatus.EXPIRED },
                  });
               },
               createUserSubscription: async (data: Prisma.UserSubscriptionCreateInput) => {
                  return tx.userSubscription.create({
                     data,
                     include: userSubscriptionIncludePlanAndFeatures,
                  }) as Promise<UserSubscriptionWithPlan>;
               },
               updateUserSubscription: async (id: number, data: Prisma.UserSubscriptionUpdateInput) => {
                  return tx.userSubscription.update({
                     where: { id },
                     data,
                     include: userSubscriptionIncludePlanAndFeatures,
                  }) as Promise<UserSubscriptionWithPlan>;
               },
               applyFeatures: async (uid: number, featurePayload: Prisma.UserFeatureCreateInput | Prisma.UserFeatureUpdateInput) => {
                  const existingFeatures = await tx.userFeature.findUnique({ where: { userId: uid } });
                  if (existingFeatures) {
                     await tx.userFeature.update({
                        where: { userId: uid },
                        data: featurePayload as Prisma.UserFeatureUpdateInput,
                     });
                  } else {
                     await tx.userFeature.create({
                        data: { user: { connect: { id: uid } }, ...(featurePayload as any) },
                     });
                  }
               },
               writeAuditLog: async (params) => {
                  await tx.userSubscriptionLog.create({
                     data: {
                        userId: params.userId,
                        previousPlanId: params.previousPlanId ?? null,
                        newPlanId: params.newPlanId ?? null,
                        previousStatus: params.previousStatus ?? null,
                        newStatus: params.newStatus,
                        reason: params.reason,
                        source: params.source,
                        eventType: params.eventType ?? "SYNC",
                        eventId: params.eventId ?? `sync_${Date.now()}_${Math.random().toString(36).substring(7)}`,
                        productId: params.productId ?? null,
                        originalTransactionId: params.originalTransactionId ?? null,
                        eventTimestampMs: params.eventTimestampMs ? BigInt(params.eventTimestampMs) : null,
                     },
                  });
               },
            };

            return operation(ctx);
         },
         {
            maxWait: 5000,
            timeout: 10000,
         }
      );
   }
}
