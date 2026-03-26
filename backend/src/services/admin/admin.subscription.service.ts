import { ApiError } from "@/utils/ApiError";
import { ISubscriptionRepository } from "../../interfaces/repositories/subscription.repository.interface";
import { IAdminSubscriptionService } from "../../interfaces/services/admin.subscription.service.interface";
import { EnrichedSubscriptionPlan } from "../../interfaces/services/user.subscription.service.interface";
import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { SYSTEM_FEATURES } from "./admin.feature.service";

export class AdminSubscriptionService implements IAdminSubscriptionService {
   constructor(private subscriptionRepository: ISubscriptionRepository) {}

   // ── Plans ────────────────────────────────────────────────────────────────

   async createPlan(data: { name: string; price: number; durationDays: number }): Promise<EnrichedSubscriptionPlan> {
      // Ensure plan name is unique (case-insensitive normalisation)
      const existing = await this.subscriptionRepository.getPlanByName(data.name.toUpperCase());
      if (existing) {
         throw new ApiError(409, `A subscription plan named '${data.name}' already exists.`);
      }

      const plan = await this.subscriptionRepository.createPlan({
         name: data.name.toUpperCase(),
         price: data.price,
         durationDays: data.durationDays,
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
      return plans.map((plan) => ({
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

   async updatePlan(id: number, data: { price?: number; durationDays?: number; isActive?: boolean }): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
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
      return this.subscriptionRepository.deletePlan(id);
   }
   // ══════════════════════════════════════════════
   // Feature Management for Plans
   // ══════════════════════════════════════════════

   async addFeatures(planId: number, features: { featureKey: string; limit: string }[]): Promise<PlanFeature[]> {
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
      const existingFeatures = await this.subscriptionRepository.getPlanFeaturesByKeys(planId, featureKeys);
      if (existingFeatures.length > 0) {
         const existingKeys = existingFeatures.map((f) => f.featureKey).join(", ");
         throw new ApiError(409, `Feature Keys [${existingKeys}] already exist for this plan`);
      }

      return await this.subscriptionRepository.addFeaturesToPlan(planId, features);
   }

   async updatePlanFeature(planFeatureId: number, limit: string): Promise<PlanFeature> {
      const existing = await this.subscriptionRepository.getPlanFeatureById(planFeatureId);
      if (!existing) {
         throw new ApiError(404, "Plan Feature mapping not found");
      }

      return await this.subscriptionRepository.updatePlanFeature(planFeatureId, limit);
   }

   async deletePlanFeature(planFeatureId: number): Promise<void> {
      const existing = await this.subscriptionRepository.getPlanFeatureById(planFeatureId);
      if (!existing) {
         throw new ApiError(404, "Plan Feature mapping not found");
      }

      await this.subscriptionRepository.deletePlanFeature(planFeatureId);
   }
}
