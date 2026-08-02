import prisma from "@/config/prisma";
import { ISubscriptionPlanRepository, PlanWithFeatures } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { Prisma, SubscriptionPlan } from "@prisma/client";

const planIncludeFeatures = {
   features: {
      orderBy: {
         createdAt: "asc",
      },
   },
} satisfies Prisma.SubscriptionPlanInclude;

export class SubscriptionPlanRepository implements ISubscriptionPlanRepository {
   /**
    * Creates a subscription plan.
    *
    * @param data - Subscription plan creation data.
    * @returns Created subscription plan with features.
    */
   async createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<PlanWithFeatures> {
      return prisma.subscriptionPlan.create({
         data,
         include: {
            features: true,
         },
      });
   }

   /**
    * Gets all subscription plans with features.
    *
    * @returns List of subscription plans with features.
    */
   async getAllPlansWithFeatures(): Promise<PlanWithFeatures[]> {
      return prisma.subscriptionPlan.findMany({
         include: planIncludeFeatures,
         orderBy: {
            createdAt: "asc",
         },
      });
   }

   /**
    * Gets a subscription plan by ID.
    *
    * @param id - Subscription plan ID.
    * @returns Subscription plan with features, or null if not found.
    */
   async getPlanById(id: number): Promise<PlanWithFeatures | null> {
      return prisma.subscriptionPlan.findUnique({
         where: {
            id,
         },
         include: planIncludeFeatures,
      });
   }

   /**
    * Gets a subscription plan by name.
    *
    * @param name - Subscription plan name.
    * @returns Subscription plan with features, or null if not found.
    */
   async getPlanByName(name: string): Promise<PlanWithFeatures | null> {
      return prisma.subscriptionPlan.findUnique({
         where: {
            name,
         },
         include: planIncludeFeatures,
      });
   }

   /**
    * Finds a subscription plan by storeProductId.
    *
    * @param storeProductId - Unique store product identifier.
    * @returns Subscription plan with features, or null if not found.
    */
   async findPlanByStoreProductId(storeProductId: string): Promise<PlanWithFeatures | null> {
      // Clean up base plan suffixes for Android (e.g., premium_monthly:monthly -> premium_monthly)
      const cleanStoreProductId = storeProductId.includes(':')
         ? storeProductId.split(':')[0]
         : storeProductId;

      return prisma.subscriptionPlan.findUnique({
         where: {
            storeProductId: cleanStoreProductId,
         },
         include: planIncludeFeatures,
      });
   }

   /**
    * Updates a subscription plan.
    *
    * @param id - Subscription plan ID.
    * @param data - Subscription plan update data.
    * @returns Updated subscription plan with features.
    */
   async updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<PlanWithFeatures> {
      return prisma.subscriptionPlan.update({
         where: {
            id,
         },
         data,
         include: {
            features: true,
         },
      });
   }

   /**
    * Removes the most popular flag from all plans.
    *
    * @returns Prisma batch update result.
    */
   async untoggleMostPopularPlans(): Promise<Prisma.BatchPayload> {
      return prisma.subscriptionPlan.updateMany({
         where: {
            isMostPopular: true,
         },
         data: {
            isMostPopular: false,
         },
      });
   }

   /**
    * Deletes a subscription plan.
    *
    * @param id - Subscription plan ID.
    * @returns Deleted subscription plan.
    */
   async deletePlan(id: number): Promise<SubscriptionPlan> {
      return prisma.subscriptionPlan.delete({
         where: {
            id,
         },
      });
   }
}
