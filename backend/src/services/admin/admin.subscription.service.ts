import { ApiError } from "@/utils/ApiError";
import { PlanFeature, SubscriptionPlan } from "@prisma/client";
import { ISubscriptionRepository, SubscriptionPlanWithFeatures } from "../../interfaces/repositories/subscription.repository.interface";
import { IAdminSubscriptionService } from "../../interfaces/services/admin.subscription.service.interface";

export class AdminSubscriptionService implements IAdminSubscriptionService {
   constructor(private subscriptionRepository: ISubscriptionRepository) {}

   // ── Plans ────────────────────────────────────────────────────────────────

   async createPlan(data: { name: string; price: number; durationDays: number }): Promise<SubscriptionPlan> {
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

   async getPlans(): Promise<SubscriptionPlanWithFeatures[]> {
      return this.subscriptionRepository.getPlans();
   }

   async getPlanById(id: number): Promise<SubscriptionPlanWithFeatures> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return plan;
   }

   async updatePlan(id: number, data: { price?: number; durationDays?: number; isActive?: boolean }): Promise<SubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return this.subscriptionRepository.updatePlan(id, data);
   }

   async deletePlan(id: number): Promise<SubscriptionPlan> {
      const plan = await this.subscriptionRepository.getPlanById(id);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");
      return this.subscriptionRepository.deletePlan(id);
   }

   // ── Features ─────────────────────────────────────────────────────────────

   async addFeatures(planId: number, features: { key: string; value: string }[]): Promise<PlanFeature[]> {
      // Verify the target plan exists
      const plan = await this.subscriptionRepository.getPlanById(planId);
      if (!plan) throw new ApiError(404, "Subscription plan not found.");

      // Check for duplicate keys within the incoming payload itself
      const payloadKeys = features.map((f) => f.key);
      const hasDuplicate = payloadKeys.length !== new Set(payloadKeys).size;
      if (hasDuplicate) throw new ApiError(400, "Duplicate feature keys found in the request payload.");

      // Check for conflict with already-stored features for this plan
      const existingKeys = plan.features.map((f) => f.key);
      const conflicting = payloadKeys.filter((k) => existingKeys.includes(k));
      if (conflicting.length > 0) {
         throw new ApiError(409, `Feature key(s) already exist on this plan: ${conflicting.join(", ")}`);
      }

      return this.subscriptionRepository.addFeatures(planId, features);
   }

   async updateFeature(featureId: number, value: string): Promise<PlanFeature> {
      const feature = await this.subscriptionRepository.getFeatureById(featureId);
      if (!feature) throw new ApiError(404, "Plan feature not found.");
      return this.subscriptionRepository.updateFeature(featureId, value);
   }

   async deleteFeature(featureId: number): Promise<PlanFeature> {
      const feature = await this.subscriptionRepository.getFeatureById(featureId);
      if (!feature) throw new ApiError(404, "Plan feature not found.");
      return this.subscriptionRepository.deleteFeature(featureId);
   }
}
