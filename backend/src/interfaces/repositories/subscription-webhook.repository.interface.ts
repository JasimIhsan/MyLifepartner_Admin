import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";

export type RevenueCatWebhookEventData = {
   id: string;
   type: RevenueCatWebhookEvent;
   app_user_id: string;
   original_app_user_id: string;
   aliases?: string[];
   event_timestamp_ms: number;
   original_transaction_id: string;
   store: string;
   environment: string;
   entitlement_id?: string;
   entitlement_ids?: string[];
   product_id: string;
   expiration_at_ms?: number;
};

export type FeatureFullPayload = {
   isProfileBlurEnabled: boolean;
   maxInterests: number;
   maxVideoCallMinutes: number;
   maxAudioCallMinutes: number;
   maxMessages: number;
   interests: number;
   videoCallMinutes: number;
   audioCallMinutes: number;
   messages: number;
};

export type FeatureLimitsOnlyPayload = {
   isProfileBlurEnabled: boolean;
   maxInterests: number;
   maxVideoCallMinutes: number;
   maxAudioCallMinutes: number;
   maxMessages: number;
};

export interface ProcessWebhookParams {
   userId: number;
   event: RevenueCatWebhookEventData;
   targetPlanId: number | null;
   freePlanId: number | undefined;
   freePlanDurationDays: number;
   defaultSubscriptionDurationDays: number;
   buildFeatureFullPayload: (plan: any) => FeatureFullPayload;
   buildFeatureLimitsOnlyPayload: (plan: any) => FeatureLimitsOnlyPayload;
}

export interface ISubscriptionWebhookRepository {
   /**
    * Processes a RevenueCat webhook event inside a database transaction.
    * 
    * Handles idempotency, advisory locking, and updates the user's subscription
    * and features based on the event type.
    * 
    * @param params - Parameters required to process the webhook event.
    * @returns A boolean indicating whether the event was processed (true) or skipped as a duplicate/invalid (false).
    */
   processWebhookEvent(params: ProcessWebhookParams): Promise<boolean>;
}
