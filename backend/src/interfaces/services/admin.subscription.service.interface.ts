import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { CreatePlanInput, UpdatePlanInput } from "@/validators/subscription.validator";

export interface AddFeaturesInput {
   featureKey: string;
   limit: string;
}


export interface IAdminSubscriptionService {
   createPlan(data: CreatePlanInput): Promise<any>;
   getPlans(): Promise<any[]>;
   getPlanById(planId: number): Promise<any>;
   updatePlan(planId: number, data: UpdatePlanInput): Promise<any>;
   deletePlan(planId: number): Promise<any>;

   addFeatures(planId: number, features: AddFeaturesInput[]): Promise<any[]>;
   updatePlanFeature(planFeatureId: number, limit: string): Promise<any>;
   deletePlanFeature(planFeatureId: number): Promise<void>;
}
