import { PlanFeature, Prisma, SubscriptionPlan, UserSubscription } from "@prisma/client";

export enum SubscriptionStatus {
   ACTIVE = "ACTIVE",
   INACTIVE = "INACTIVE",
   CANCELLED = "CANCELLED",
   EXPIRED = "EXPIRED",
}
export type UserSubscriptionWithPlan = UserSubscription & {
   plan: SubscriptionPlan & {
      features: PlanFeature[];
   };
};

export interface IUserSubscriptionRepository {
   createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<UserSubscriptionWithPlan>;
   findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null>;
   deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload>;
   updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<UserSubscriptionWithPlan>;
}
