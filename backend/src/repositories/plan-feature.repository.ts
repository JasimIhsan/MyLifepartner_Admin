import prisma from "@/config/prisma";
import { CreatePlanFeatureData, IPlanFeatureRepository, UpdatePlanFeatureData } from "@/interfaces/repositories/plan-feature.repository.interface";
import { PlanFeature } from "@prisma/client";

export class PlanFeatureRepository implements IPlanFeatureRepository {
   /**
    * Adds features to a subscription plan.
    *
    * @param planId - Subscription plan ID.
    * @param featureData - Plan feature creation data.
    * @returns Created or existing plan features.
    */
   async addFeaturesToPlan(planId: number, featureData: CreatePlanFeatureData[]): Promise<PlanFeature[]> {
      const data = featureData.map((feature) => ({
         planId,
         featureKey: feature.featureKey,
         limit: feature.limit,
         description: feature.description,
      }));

      await prisma.planFeature.createMany({
         data,
         skipDuplicates: true,
      });

      const featureKeys = featureData.map((feature) => feature.featureKey);

      return prisma.planFeature.findMany({
         where: {
            planId,
            featureKey: {
               in: featureKeys,
            },
         },
      });
   }

   /**
    * Gets plan features by feature keys.
    *
    * @param planId - Subscription plan ID.
    * @param featureKeys - Plan feature keys.
    * @returns Matching plan features.
    */
   async getPlanFeaturesByKeys(planId: number, featureKeys: string[]): Promise<PlanFeature[]> {
      return prisma.planFeature.findMany({
         where: {
            planId,
            featureKey: {
               in: featureKeys,
            },
         },
      });
   }

   /**
    * Gets a plan feature by ID.
    *
    * @param id - Plan feature ID.
    * @returns Plan feature, or null if not found.
    */
   async getPlanFeatureById(id: number): Promise<PlanFeature | null> {
      return prisma.planFeature.findUnique({
         where: {
            id,
         },
      });
   }

   /**
    * Updates a plan feature.
    *
    * @param id - Plan feature ID.
    * @param data - Plan feature update data.
    * @returns Updated plan feature.
    */
   async updatePlanFeature(id: number, data: UpdatePlanFeatureData): Promise<PlanFeature> {
      return prisma.planFeature.update({
         where: {
            id,
         },
         data,
      });
   }

   /**
    * Deletes a plan feature.
    *
    * @param id - Plan feature ID.
    * @returns Deleted plan feature.
    */
   async deletePlanFeature(id: number): Promise<PlanFeature> {
      return prisma.planFeature.delete({
         where: {
            id,
         },
      });
   }
}
