import { CreatePlanInput, UpdatePlanInput } from "@/validators/subscription.validator";
import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { EnrichedSubscriptionPlan } from "./user.subscription.service.interface";

export interface AddFeaturesInput {
   featureKey: string;
   limit: string;
   description?: string;
}

export interface IAdminSubscriptionService {
   createPlan(data: CreatePlanInput): Promise<EnrichedSubscriptionPlan>;
   getPlans(): Promise<EnrichedSubscriptionPlan[]>;
   getPlanById(planId: number): Promise<EnrichedSubscriptionPlan>;
   updatePlan(planId: number, data: UpdatePlanInput): Promise<EnrichedSubscriptionPlan>;
   deletePlan(planId: number): Promise<SubscriptionPlan>;

   addFeatures(planId: number, features: AddFeaturesInput[]): Promise<PlanFeature[]>;
   updatePlanFeature(planFeatureId: number, data: { limit?: string; description?: string }): Promise<PlanFeature>;
   deletePlanFeature(planFeatureId: number): Promise<void>;
}
