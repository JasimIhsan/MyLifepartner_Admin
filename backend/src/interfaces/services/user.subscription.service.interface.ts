import { Feature } from "./admin.feature.service.interface";
import { UserSubscription } from "@prisma/client";
import { UserFeature } from "./user.feature.service.interface";

export interface SubscriptionPlan {
   id: number;
   name: string;
   description: string | null;
   price: number;
   durationDays: number;
   isActive: boolean;
   isMostPopular: boolean;
   storeProductId: string | null;
   createdAt: Date;
   updatedAt: Date;
}

export interface PlanFeature {
   id: number;
   planId: number;
   featureKey: string;
   description: string | null;
   limit: string;
   createdAt: Date;
   updatedAt: Date;
}

export type EnrichedPlanFeature = PlanFeature & { feature?: Feature };
export type EnrichedSubscriptionPlan = SubscriptionPlan & { features: EnrichedPlanFeature[] };
export interface EnrichedUserSubscription extends UserSubscription {
   plan: EnrichedSubscriptionPlan;
   message?: string;
};

export interface IUserSubscriptionService {
   getPlans(): Promise<EnrichedSubscriptionPlan[]>;
   getMySubscription(userId: number): Promise<EnrichedUserSubscription | null>;
   subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription>;
   getUserFeatures(userId: number): Promise<UserFeature | null>;
   reconcileUserSubscription(userId: number): Promise<void>;
   syncSubscription(userId: number): Promise<EnrichedUserSubscription | null>;
   handleWebhook(payload: Record<string, unknown>, signatureHeader?: string): Promise<void>;
}
