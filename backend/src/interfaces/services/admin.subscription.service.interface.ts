import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { SubscriptionPlanWithFeatures } from "../repositories/subscription.repository.interface";

export interface IAdminSubscriptionService {
   // ── Plans ──────────────────────────────────────────────────────────────
   createPlan(data: { name: string; price: number; durationDays: number }): Promise<SubscriptionPlan>;
   getPlans(): Promise<SubscriptionPlanWithFeatures[]>;
   getPlanById(id: number): Promise<SubscriptionPlanWithFeatures>;
   updatePlan(id: number, data: { price?: number; durationDays?: number; isActive?: boolean }): Promise<SubscriptionPlan>;
   deletePlan(id: number): Promise<SubscriptionPlan>;

   // ── Features ───────────────────────────────────────────────────────────
   addFeatures(planId: number, features: { key: string; value: string }[]): Promise<PlanFeature[]>;
   updateFeature(featureId: number, value: string): Promise<PlanFeature>;
   deleteFeature(featureId: number): Promise<PlanFeature>;
}
