import { EnrichedUserSubscription, EnrichedSubscriptionPlan, EnrichedPlanFeature } from "@/interfaces/services/user.subscription.service.interface";

export interface PlanFeatureDto {
   id: number;
   planId: number;
   featureKey: string;
   description: string | null;
   limit: string;
   createdAt: Date;
   updatedAt: Date;
   feature?: unknown;
}

export interface SubscriptionPlanDto {
   id: number;
   name: string;
   description: string | null;
   price: number;
   durationDays: number;
   isActive: boolean;
   isMostPopular: boolean;
   identifier: string | null;
   createdAt: Date;
   updatedAt: Date;
   features: PlanFeatureDto[];
}

export interface UserSubscriptionDto {
   id: number;
   userId: number;
   planId: number;
   startDate: Date;
   endDate: Date;
   status: string;
   willRenew: boolean;
   nextPlanId: number | null;
   createdAt: Date;
   updatedAt: Date;
   revenueCatEventId: string | null;
   lastEventTimestampMs: number | string | null;
   originalTransactionId: string | null;
   store: string | null;
   environment: string | null;
   plan: SubscriptionPlanDto;
   message?: string;
}

export const toPlanFeatureDto = (feature: EnrichedPlanFeature): PlanFeatureDto => ({
   id: feature.id,
   planId: feature.planId,
   featureKey: feature.featureKey,
   description: feature.description,
   limit: feature.limit,
   createdAt: feature.createdAt,
   updatedAt: feature.updatedAt,
   feature: feature.feature,
});

export const toSubscriptionPlanDto = (plan: EnrichedSubscriptionPlan): SubscriptionPlanDto => ({
   id: plan.id,
   name: plan.name,
   description: plan.description,
   price: plan.price,
   durationDays: plan.durationDays,
   isActive: plan.isActive,
   isMostPopular: plan.isMostPopular,
   identifier: plan.identifier,
   createdAt: plan.createdAt,
   updatedAt: plan.updatedAt,
   features: plan.features.map(toPlanFeatureDto),
});

export const toUserSubscriptionDto = (sub: EnrichedUserSubscription): UserSubscriptionDto => ({
   id: sub.id,
   userId: sub.userId,
   planId: sub.planId,
   startDate: sub.startDate,
   endDate: sub.endDate,
   status: sub.status,
   willRenew: sub.willRenew,
   nextPlanId: sub.nextPlanId,
   createdAt: sub.createdAt,
   updatedAt: sub.updatedAt,
   revenueCatEventId: sub.revenueCatEventId,
   lastEventTimestampMs: sub.lastEventTimestampMs !== null && sub.lastEventTimestampMs !== undefined
      ? (Number.isSafeInteger(Number(sub.lastEventTimestampMs)) ? Number(sub.lastEventTimestampMs) : sub.lastEventTimestampMs.toString())
      : null,
   originalTransactionId: sub.originalTransactionId,
   store: sub.store,
   environment: sub.environment,
   plan: toSubscriptionPlanDto(sub.plan),
   message: sub.message,
});
