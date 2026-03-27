import { PlanFeature, Prisma, SubscriptionPlan } from "@prisma/client";

export interface ISubscriptionRepository {
   // -- Plans --
   createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<SubscriptionPlan & { features: PlanFeature[] }>;
   getPlanByName(name: string): Promise<SubscriptionPlan | null>;
   getAllPlansWithFeatures(): Promise<(SubscriptionPlan & { features: PlanFeature[] })[]>;
   getPlanById(id: number): Promise<(SubscriptionPlan & { features: PlanFeature[] }) | null>;
   updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<SubscriptionPlan & { features: PlanFeature[] }>;
   deletePlan(id: number): Promise<SubscriptionPlan>;
   untoggleMostPopularPlans(): Promise<Prisma.BatchPayload>;

   // -- Features (Plan logic) --
   addFeaturesToPlan(planId: number, featureData: { featureKey: string; limit: string }[]): Promise<PlanFeature[]>;
   getPlanFeaturesByKeys(planId: number, featureKeys: string[]): Promise<PlanFeature[]>;
   getPlanFeatureById(id: number): Promise<PlanFeature | null>;
   updatePlanFeature(id: number, limit: string): Promise<PlanFeature>;
   deletePlanFeature(id: number): Promise<PlanFeature>;

   // -- User Subscriptions --
   createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }>;
   findActiveSubscriptionByUserId(userId: number): Promise<(import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }) | null>;
   deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload>;
}
