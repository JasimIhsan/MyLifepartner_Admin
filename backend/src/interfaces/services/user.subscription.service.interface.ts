import { UserSubscription } from "@prisma/client";
import { Feature } from "./admin.feature.service.interface";
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
   isExpired?: boolean;
   isGracePeriod?: boolean;
   isPaymentFailed?: boolean;
   isDowngradeScheduled?: boolean;
   isCancelled?: boolean;
}

/**
 * Parameters sent by the Flutter app after a successful RevenueCat purchase.
 * The backend uses these to verify the transaction against the RC REST API and
 * immediately activate the subscription — without waiting for a webhook.
 */
export interface VerifyPurchaseParams {
   /**
    * Store transaction identifier returned by RevenueCat/StoreKit/Play Billing.
    * Older clients sent this under originalTransactionId, so the service keeps
    * that field as a compatibility fallback.
    */
   storeTransactionId?: string;
   /** Legacy client field; do not send RevenueCat originalAppUserId here. */
   originalTransactionId?: string;
   /** Store product identifier that was purchased */
   productId: string;
   /** "PLAY_STORE" | "APP_STORE" | "STRIPE" etc. */
   store: string;
   /** "PRODUCTION" | "SANDBOX" */
   environment: string;
}

export interface IUserSubscriptionService {
   getPlans(): Promise<EnrichedSubscriptionPlan[]>;
   getMySubscription(userId: number): Promise<EnrichedUserSubscription | null>;
   subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription>;
   getUserFeatures(userId: number): Promise<UserFeature | null>;
   reconcileUserSubscription(userId: number): Promise<void>;
   syncSubscription(userId: number): Promise<EnrichedUserSubscription | null>;
   handleWebhook(payload: Record<string, unknown>, signatureHeader?: string): Promise<void>;
   /**
    * Verifies a purchase with the RevenueCat REST API and immediately activates
    * the corresponding plan in the database. Replaces the /sync post-purchase
    * call so that the user's new plan is applied within the same request as the
    * purchase confirmation — no webhook latency.
    */
   verifyAndActivatePurchase(userId: number, params: VerifyPurchaseParams): Promise<EnrichedUserSubscription>;
}
