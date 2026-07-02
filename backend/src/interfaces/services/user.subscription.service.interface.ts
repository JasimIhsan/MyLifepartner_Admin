import { Feature } from "./admin.feature.service.interface";
import { SubscriptionPlan, UserSubscription, UserFeature, PlanFeature } from "@prisma/client";

export type EnrichedPlanFeature = PlanFeature & { feature?: Feature };
export type EnrichedSubscriptionPlan = SubscriptionPlan & { features: EnrichedPlanFeature[] };
export type EnrichedUserSubscription = UserSubscription & { plan: EnrichedSubscriptionPlan };

export interface IUserSubscriptionService {
   getPlans(): Promise<EnrichedSubscriptionPlan[]>;
   getMySubscription(userId: number): Promise<EnrichedUserSubscription | null>;
   subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription>;
   getUserFeatures(userId: number): Promise<UserFeature | null>;
   syncSubscription(userId: number): Promise<any>;
   handleWebhook(payload: any, signatureHeader?: string): Promise<void>;
}
