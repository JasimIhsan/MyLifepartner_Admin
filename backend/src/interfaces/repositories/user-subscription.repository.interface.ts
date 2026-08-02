import { PlanFeature, Prisma, SubscriptionPlan, UserSubscription } from "@prisma/client";

export enum SubscriptionStatus {
   ACTIVE = "ACTIVE",
   INACTIVE = "INACTIVE",
   CANCELLED = "CANCELLED",
   CANCELLED_PENDING_EXPIRY = "CANCELLED_PENDING_EXPIRY",
   /**
    * Payment has failed; store is retrying. User retains premium access
    * during the store grace period. Resolves to ACTIVE on recovery or
    * GRACE_PERIOD if the store grace period ends without recovery.
    */
   BILLING_ISSUE = "BILLING_ISSUE",
   /**
    * Store grace period ended but backend is still reconciling against RC API.
    * User retains premium access for GRACE_PERIOD_DAYS before FREE downgrade.
    */
   GRACE_PERIOD = "GRACE_PERIOD",
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
      eventType?: string;
      eventId?: string;
      productId?: string;
      originalTransactionId?: string;
      transactionId?: string;
      store?: string;
      environment?: string;
      eventTimestampMs?: bigint | number;
   }): Promise<void>;
}

export interface IUserSubscriptionRepository {
   createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<UserSubscriptionWithPlan>;
   findActiveSubscriptionByUserId(userId: number): Promise<UserSubscriptionWithPlan | null>;
   deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload>;
   updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<UserSubscriptionWithPlan>;
   executeSyncTransaction<T>(userId: number, operation: (ctx: ISyncTransactionContext) => Promise<T>): Promise<T>;
}
