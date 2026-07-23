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

export interface ISyncTransactionContext {
   findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null>;
   deactivateUserSubscriptions(userId: number): Promise<void>;
   createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<UserSubscriptionWithPlan>;
   updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<UserSubscriptionWithPlan>;
   applyFeatures(userId: number, featurePayload: Prisma.UserFeatureCreateInput | Prisma.UserFeatureUpdateInput): Promise<void>;
   writeAuditLog(params: {
      userId: number;
      previousPlanId?: number | null;
      newPlanId?: number | null;
      previousStatus?: string;
      newStatus: string;
      reason: string;
      source: string;
   }): Promise<void>;
}

export interface IUserSubscriptionRepository {
   createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<UserSubscriptionWithPlan>;
   findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null>;
   deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload>;
   updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<UserSubscriptionWithPlan>;
   executeSyncTransaction<T>(userId: number, operation: (ctx: ISyncTransactionContext) => Promise<T>): Promise<T>;
}
