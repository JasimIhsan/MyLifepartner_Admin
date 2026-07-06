import { SYSTEM_FEATURES } from "@/constants/SYSTEM_FEATURES";
import { FeatureKey } from "@/enums/feature-key.enum";
import { IPlanFeatureRepository } from "@/interfaces/repositories/plan-feature.repository.interface";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IAdminSubscriptionService } from "@/interfaces/services/admin.subscription.service.interface";
import { EnrichedSubscriptionPlan } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { PlanFeature, SubscriptionPlan } from "@/interfaces/services/user.subscription.service.interface";

type CreateSubscriptionPlanData = {
   name: string;
   price: number;
   durationDays: number;
   identifier: string;
   description?: string;
};

type UpdateSubscriptionPlanData = {
   price?: number;
   durationDays?: number;
   isActive?: boolean;
   isMostPopular?: boolean;
   identifier?: string;
};

type AddPlanFeatureData = {
   featureKey: FeatureKey;
   limit: string;
   description?: string;
};

type UpdatePlanFeatureData = {
   limit?: string;
   description?: string;
};

const FREE_PLAN_NAME = "FREE";

export class AdminSubscriptionService implements IAdminSubscriptionService {
   constructor(
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly planFeatureRepository: IPlanFeatureRepository
   ) {}

   /**
    * Creates a subscription plan.
    *
    * @param data - Subscription plan creation data.
    * @returns Created subscription plan with enriched features.
    */
   async createPlan(data: CreateSubscriptionPlanData): Promise<EnrichedSubscriptionPlan> {
      const normalizedPlanName = this.normalizePlanName(data.name);

      await this.ensurePlanNameIsAvailable(normalizedPlanName);

      const plan = await this.subscriptionPlanRepository.createPlan({
         name: normalizedPlanName,
         price: data.price,
         durationDays: data.durationDays,
         identifier: data.identifier,
         description: data.description,
      });

      return this.enrichPlan(plan);
   }

   /**
    * Gets subscription plans.
    *
    * @returns Subscription plans with enriched features.
    */
   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionPlanRepository.getAllPlansWithFeatures() as unknown as (SubscriptionPlan & { features: PlanFeature[] })[];

      return this.sortFreePlanFirst(plans).map((plan) => this.enrichPlan(plan));
   }

   /**
    * Gets subscription plan by ID.
    *
    * @param id - Subscription plan ID.
    * @returns Subscription plan with enriched features.
    */
   async getPlanById(id: number): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.getRequiredPlan(id);

      return this.enrichPlan(plan);
   }

   /**
    * Updates a subscription plan.
    *
    * @param id - Subscription plan ID.
    * @param data - Subscription plan update data.
    * @returns Updated subscription plan with enriched features.
    */
   async updatePlan(id: number, data: UpdateSubscriptionPlanData): Promise<EnrichedSubscriptionPlan> {
      await this.getRequiredPlan(id);

      if (data.isMostPopular) {
         await this.subscriptionPlanRepository.untoggleMostPopularPlans();
      }

      const updatedPlan = await this.subscriptionPlanRepository.updatePlan(id, data) as SubscriptionPlan & { features: PlanFeature[] };

      return this.enrichPlan(updatedPlan);
   }

   /**
    * Deletes a subscription plan.
    *
    * @param id - Subscription plan ID.
    * @returns Deleted subscription plan.
    */
   async deletePlan(id: number): Promise<SubscriptionPlan> {
      const plan = await this.getRequiredPlan(id);

      if (plan.name === FREE_PLAN_NAME) {
         throw new ApiError(403, "Cannot delete the FREE plan.");
      }

      return this.subscriptionPlanRepository.deletePlan(id);
   }

   /**
    * Adds features to a subscription plan.
    *
    * @param planId - Subscription plan ID.
    * @param features - Plan feature creation data.
    * @returns Created plan features.
    */
   async addFeatures(planId: number, features: AddPlanFeatureData[]): Promise<PlanFeature[]> {
      await this.getRequiredPlan(planId);
      this.ensureNoDuplicateFeatureKeys(features);

      const featureKeys = features.map((feature) => feature.featureKey);
      const existingFeatures = await this.planFeatureRepository.getPlanFeaturesByKeys(planId, featureKeys);

      if (existingFeatures.length > 0) {
         const existingKeys = existingFeatures.map((feature) => feature.featureKey).join(", ");

         throw new ApiError(409, `Feature keys [${existingKeys}] already exist for this plan`);
      }

      return this.planFeatureRepository.addFeaturesToPlan(planId, features) as unknown as PlanFeature[];
   }

   /**
    * Updates a plan feature.
    *
    * @param planFeatureId - Plan feature ID.
    * @param data - Plan feature update data.
    * @returns Updated plan feature.
    */
   async updatePlanFeature(planFeatureId: number, data: UpdatePlanFeatureData): Promise<PlanFeature> {
      await this.getRequiredPlanFeature(planFeatureId);

      return this.planFeatureRepository.updatePlanFeature(planFeatureId, data) as unknown as PlanFeature;
   }

   /**
    * Deletes a plan feature.
    *
    * @param planFeatureId - Plan feature ID.
    * @returns Nothing.
    */
   async deletePlanFeature(planFeatureId: number): Promise<void> {
      await this.getRequiredPlanFeature(planFeatureId);

      await this.planFeatureRepository.deletePlanFeature(planFeatureId);
   }

   /**
    * Gets required subscription plan.
    *
    * @param planId - Subscription plan ID.
    * @returns Subscription plan with features.
    */
   private async getRequiredPlan(planId: number) {
      const plan = await this.subscriptionPlanRepository.getPlanById(planId);

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found.");
      }

      return plan as unknown as EnrichedSubscriptionPlan;
   }

   /**
    * Gets required plan feature.
    *
    * @param planFeatureId - Plan feature ID.
    * @returns Plan feature.
    */
   private async getRequiredPlanFeature(planFeatureId: number): Promise<PlanFeature> {
      const planFeature = await this.planFeatureRepository.getPlanFeatureById(planFeatureId);

      if (!planFeature) {
         throw new ApiError(404, "Plan feature mapping not found");
      }

      return planFeature;
   }

   /**
    * Checks subscription plan name availability.
    *
    * @param name - Subscription plan name.
    * @returns Nothing.
    */
   private async ensurePlanNameIsAvailable(name: string): Promise<void> {
      const existingPlan = await this.subscriptionPlanRepository.getPlanByName(name);

      if (existingPlan) {
         throw new ApiError(409, `A subscription plan named '${name}' already exists.`);
      }
   }

   /**
    * Checks duplicate feature keys.
    *
    * @param features - Plan features.
    * @returns Nothing.
    */
   private ensureNoDuplicateFeatureKeys(features: AddPlanFeatureData[]): void {
      const featureKeys = features.map((feature) => feature.featureKey);
      const uniqueFeatureKeys = new Set(featureKeys);

      if (uniqueFeatureKeys.size !== featureKeys.length) {
         throw new ApiError(400, "Duplicate features in request");
      }
   }

   /**
    * Enriches subscription plan features.
    *
    * @param plan - Subscription plan with features.
    * @returns Enriched subscription plan.
    */
   private enrichPlan(plan: SubscriptionPlan & { features: PlanFeature[] }): EnrichedSubscriptionPlan {
      return {
         ...plan,
         features: plan.features.map((planFeature) => ({
            ...planFeature,
            feature: SYSTEM_FEATURES.find((systemFeature) => systemFeature.key === planFeature.featureKey),
         })),
      } as EnrichedSubscriptionPlan;
   }

   /**
    * Sorts FREE plan first.
    *
    * @param plans - Subscription plans.
    * @returns Sorted subscription plans.
    */
   private sortFreePlanFirst<T extends SubscriptionPlan>(plans: T[]): T[] {
      return [...plans].sort((firstPlan, secondPlan) => {
         if (firstPlan.name === FREE_PLAN_NAME) {
            return -1;
         }

         if (secondPlan.name === FREE_PLAN_NAME) {
            return 1;
         }

         return 0;
      });
   }

   /**
    * Normalizes subscription plan name.
    *
    * @param name - Subscription plan name.
    * @returns Normalized plan name.
    */
   private normalizePlanName(name: string): string {
      return name.trim().toUpperCase();
   }
}
