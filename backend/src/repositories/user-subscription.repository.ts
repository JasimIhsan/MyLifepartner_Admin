import prisma from "@/config/prisma";
import { IUserSubscriptionRepository, UserSubscriptionWithPlan } from "@/interfaces/repositories/user-subscription.repository.interface";
import { Prisma, SubscriptionStatus as PrismaSubscriptionStatus } from "@prisma/client";
import { SubscriptionStatus } from "@/interfaces/repositories/user-subscription.repository.interface";

const userSubscriptionIncludePlanAndFeatures = {
   plan: {
      include: {
         features: true,
      },
   },
} satisfies Prisma.UserSubscriptionInclude;

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
    * @param userId - User ID.
    * @returns Active user subscription with plan and features, or null if not found.
    */
   async findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null> {
      return prisma.userSubscription.findFirst({
         where: {
            userId,
            status: SubscriptionStatus.ACTIVE as unknown as PrismaSubscriptionStatus,
         },
         include: userSubscriptionIncludePlanAndFeatures,
         orderBy: {
            createdAt: "desc",
         },
      }) as Promise<UserSubscriptionWithPlan | null>;
   }

   /**
    * Deactivates active subscriptions of a user.
    *
    * @param userId - User ID.
    * @returns Prisma batch update result.
    */
   async deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload> {
      return prisma.userSubscription.updateMany({
         where: {
            userId,
            status: SubscriptionStatus.ACTIVE as unknown as PrismaSubscriptionStatus,
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
}
