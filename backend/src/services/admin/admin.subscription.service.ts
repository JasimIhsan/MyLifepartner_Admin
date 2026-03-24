import { ApiError } from "@/utils/ApiError";
import { ISubscriptionRepository } from "../../interfaces/repositories/subscription.repository.interface";
import { IAdminSubscriptionService } from "../../interfaces/services/admin.subscription.service.interface";

export class AdminSubscriptionService implements IAdminSubscriptionService {
   constructor(private subscriptionRepository: ISubscriptionRepository) {}

   // ── Plans ────────────────────────────────────────────────────────────────

   async createPlan(data: { name: string; price: number; durationDays: number }): Promise<any> {
      // Ensure plan name is unique (case-insensitive normalisation)
      const existing = await this.subscriptionRepository.getPlanByName(data.name.toUpperCase());
      if (existing) {
         throw new ApiError(409, `A subscription plan named '${data.name}' already exists.`);
      }

      return this.subscriptionRepository.createPlan({
         name: data.name.toUpperCase(),
         price: data.price,
         durationDays: data.durationDays,
      });
   }

   async getPlans(): Promise<any[]> {
      return this.subscriptionRepository.getAllPlansWithFeatures();
   }

   async getPlanById(id: number): Promise<any> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return plan;
   }

   async updatePlan(id: number, data: { price?: number; durationDays?: number; isActive?: boolean }): Promise<any> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return this.subscriptionRepository.updatePlan(id, data);
   }

   async deletePlan(id: number): Promise<any> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return this.subscriptionRepository.deletePlan(id);
   }
   // ══════════════════════════════════════════════
   // Feature Management for Plans
   // ══════════════════════════════════════════════

   async addFeatures(planId: number, features: { featureId: number; limit: string }[]): Promise<any[]> {
      // 1. Ensure plan exists
      await this.getPlanById(planId);

      // 2. Check for duplicate assignments
      // The payload shouldn't have duplicate featureIds for the same request
      const featureIds = features.map((f) => f.featureId);
      const uniqueFeatureIds = new Set(featureIds);
      if (uniqueFeatureIds.size !== featureIds.length) {
         throw new ApiError(400, "Duplicate features in request");
      }

      // Check against DB
      const existingFeatures = await this.subscriptionRepository.getPlanFeaturesByKeys(planId, featureIds);
      if (existingFeatures.length > 0) {
         const existingIds = existingFeatures.map((f) => f.featureId).join(", ");
         throw new ApiError(409, `Feature IDs [${existingIds}] already exist for this plan`);
      }

      return await this.subscriptionRepository.addFeaturesToPlan(planId, features);
   }

   async updatePlanFeature(planFeatureId: number, limit: string): Promise<any> {
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
