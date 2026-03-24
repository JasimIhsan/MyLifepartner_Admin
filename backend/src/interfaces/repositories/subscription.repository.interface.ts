import { PlanFeature, Prisma, SubscriptionPlan } from "@prisma/client";

// ─── Return type: plan with its features array ─────────────────────────────
export type SubscriptionPlanWithFeatures = SubscriptionPlan & {
   features: PlanFeature[];
};

export interface ISubscriptionRepository {
   // ── Plans ──────────────────────────────────────────────────────────────
   createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<SubscriptionPlan>;
   getPlans(): Promise<SubscriptionPlanWithFeatures[]>;
   getPlanById(id: number): Promise<SubscriptionPlanWithFeatures | null>;
   getPlanByName(name: string): Promise<SubscriptionPlan | null>;
   updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<SubscriptionPlan>;
   deletePlan(id: number): Promise<SubscriptionPlan>;

   // ── Features ───────────────────────────────────────────────────────────
   addFeatures(planId: number, features: { key: string; value: string }[]): Promise<PlanFeature[]>;
   getFeatureById(id: number): Promise<PlanFeature | null>;
   updateFeature(id: number, value: string): Promise<PlanFeature>;
   deleteFeature(id: number): Promise<PlanFeature>;
}
