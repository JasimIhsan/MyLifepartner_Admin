import { PlanFeature } from "@prisma/client";

export type CreatePlanFeatureData = {
   featureKey: string;
   limit: string;
   description?: string;
};

export type UpdatePlanFeatureData = {
   limit?: string;
   description?: string;
};

export interface IPlanFeatureRepository {
   addFeaturesToPlan(planId: number, featureData: CreatePlanFeatureData[]): Promise<PlanFeature[]>;
   getPlanFeaturesByKeys(planId: number, featureKeys: string[]): Promise<PlanFeature[]>;
   getPlanFeatureById(id: number): Promise<PlanFeature | null>;
   updatePlanFeature(id: number, data: UpdatePlanFeatureData): Promise<PlanFeature>;
   deletePlanFeature(id: number): Promise<PlanFeature>;
}
