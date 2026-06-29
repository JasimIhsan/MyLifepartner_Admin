import { ApiError } from "@/utils/ApiError";
import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { SYSTEM_FEATURES } from "../../constants/SYSTEM_FEATURES";
import { ISubscriptionRepository } from "../../interfaces/repositories/subscription.repository.interface";
import { IAdminSubscriptionService } from "../../interfaces/services/admin.subscription.service.interface";
import { EnrichedSubscriptionPlan } from "../../interfaces/services/user.subscription.service.interface";
import { FeatureKey } from "../../enums/feature-key.enum";

export class AdminSubscriptionService implements IAdminSubscriptionService {
   constructor(private subscriptionRepository: ISubscriptionRepository) {}

   // ── Plans ────────────────────────────────────────────────────────────────

   async createPlan(data: { name: string; price: number; durationDays: number; identifier: string; description?: string }): Promise<EnrichedSubscriptionPlan> {
      // Ensure plan name is unique (case-insensitive normalisation)
      const existing = await this.subscriptionRepository.getPlanByName(data.name.toUpperCase());
      if (existing) {
         throw new ApiError(409, `A subscription plan named '${data.name}' already exists.`);
      }

      const plan = await this.subscriptionRepository.createPlan({
         name: data.name.toUpperCase(),
         price: data.price,
         durationDays: data.durationDays,
         identifier: data.identifier,
         description: data.description,
      });

      return {
         ...plan,
         features: plan.features.map((pf) => ({
            ...pf,
            feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
         })),
      } as EnrichedSubscriptionPlan;
   }

   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionRepository.getAllPlansWithFeatures();

      // Ensure FREE plan is always first
      const sortedPlans = [...plans].sort((a, b) => {
         if (a.name === "FREE") return -1;
         if (b.name === "FREE") return 1;
         return 0;
      });

      return sortedPlans.map((plan) => ({
         ...plan,
         features: plan.features.map((pf) => ({
            ...pf,
            feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
         })),
      })) as EnrichedSubscriptionPlan[];
   }

   async getPlanById(id: number): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return {
         ...plan,
         features: plan.features.map((pf) => ({
            ...pf,
            feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
         })),
      } as EnrichedSubscriptionPlan;
   }

   async updatePlan(id: number, data: { price?: number; durationDays?: number; isActive?: boolean; isMostPopular?: boolean; identifier?: string }): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");

      if (data.isMostPopular) {
         await this.subscriptionRepository.untoggleMostPopularPlans();
      }

      const updated = await this.subscriptionRepository.updatePlan(id, data);
      return {
         ...updated,
         features: updated.features.map((pf) => ({
            ...pf,
            feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
         })),
      } as EnrichedSubscriptionPlan;
   }

   async deletePlan(id: number): Promise<SubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      if (plan.name === "FREE") throw new ApiError(403, "Cannot delete the FREE plan.");
      return this.subscriptionRepository.deletePlan(id);
   }
   // ══════════════════════════════════════════════
   // Feature Management for Plans
   // ══════════════════════════════════════════════

   async addFeatures(planId: number, features: { featureKey: FeatureKey; limit: string; description?: string }[]): Promise<PlanFeature[]> {
      // 1. Ensure plan exists
      await this.getPlanById(planId);

      // 2. Check for duplicate assignments
      // The payload shouldn't have duplicate featureKeys for the same request
      const featureKeys = features.map((f) => f.featureKey);
      const uniqueFeatureKeys = new Set(featureKeys);
      if (uniqueFeatureKeys.size !== featureKeys.length) {
         throw new ApiError(400, "Duplicate features in request");
      }

      // Check against DB
      const existingFeatures = await this.subscriptionRepository.getPlanFeaturesByKeys(planId, featureKeys as any);
      if (existingFeatures.length > 0) {
         const existingKeys = existingFeatures.map((f) => f.featureKey).join(", ");
         throw new ApiError(409, `Feature Keys [${existingKeys}] already exist for this plan`);
      }

      return await this.subscriptionRepository.addFeaturesToPlan(planId, features as any);
   }

   async updatePlanFeature(planFeatureId: number, data: { limit?: string; description?: string }): Promise<PlanFeature> {
      const existing = await this.subscriptionRepository.getPlanFeatureById(planFeatureId);
      if (!existing) {
         throw new ApiError(404, "Plan Feature mapping not found");
      }

      return await this.subscriptionRepository.updatePlanFeature(planFeatureId, data);
   }

   async deletePlanFeature(planFeatureId: number): Promise<void> {
      const existing = await this.subscriptionRepository.getPlanFeatureById(planFeatureId);
      if (!existing) {
         throw new ApiError(404, "Plan Feature mapping not found");
      }

      await this.subscriptionRepository.deletePlanFeature(planFeatureId);
   }
}
