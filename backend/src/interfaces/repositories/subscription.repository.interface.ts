import { PlanFeature, Prisma, SubscriptionPlan } from "@prisma/client";

export interface ISubscriptionRepository {
   // -- Plans --
   createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<SubscriptionPlan & { features: any[] }>;
   getPlanByName(name: string): Promise<SubscriptionPlan | null>;
   getAllPlansWithFeatures(): Promise<(SubscriptionPlan & { features: any[] })[]>;
   getPlanById(id: number): Promise<(SubscriptionPlan & { features: any[] }) | null>;
   updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<SubscriptionPlan & { features: any[] }>;
   deletePlan(id: number): Promise<SubscriptionPlan>;

   // -- Features (Plan logic) --
   addFeaturesToPlan(planId: number, featureData: { featureKey: string; limit: string }[]): Promise<any[]>;
   getPlanFeaturesByKeys(planId: number, featureKeys: string[]): Promise<any[]>;
   getPlanFeatureById(id: number): Promise<any | null>;
   updatePlanFeature(id: number, limit: string): Promise<any>;
   deletePlanFeature(id: number): Promise<any>;
}

