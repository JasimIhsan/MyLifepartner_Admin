import { SYSTEM_FEATURES } from "@/constants/SYSTEM_FEATURES";
import { FeatureKey } from "@/enums/feature-key.enum";
import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { IProcessedRevenueCatEventRepository } from "@/interfaces/repositories/processed-revenuecat-event.repository.interface";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IUserSubscriptionRepository, SubscriptionStatus } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { UserFeature } from "@/interfaces/services/user.feature.service.interface";
import { EnrichedSubscriptionPlan, EnrichedUserSubscription, IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";

type RevenueCatSubscription = {
   expires_date?: string;
   purchase_date?: string;
   unsubscribe_detected_at?: string;
};

type RevenueCatSubscriberResponse = {
   subscriber?: {
      subscriptions?: Record<string, RevenueCatSubscription>;
   };
};

type RevenueCatWebhookEventData = {
   id: string;
   type: RevenueCatWebhookEvent;
   app_user_id: string;
};

type FeatureLimitPayload = {
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

const FREE_PLAN_NAME = "FREE";
const DEFAULT_SUBSCRIPTION_DURATION_DAYS = 30;
const MS_PER_DAY = 24 * 60 * 60 * 1000;

export class UserSubscriptionService implements IUserSubscriptionService {
   constructor(
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly userSubscriptionRepository: IUserSubscriptionRepository,
      private readonly processedRevenueCatEventRepository: IProcessedRevenueCatEventRepository,
      private readonly userFeatureRepository: IUserFeatureRepository
   ) {}

   /**
    * Gets subscription plans.
    *
    * @returns Enriched subscription plans.
    */
   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionPlanRepository.getAllPlansWithFeatures();

      return this.sortPlans(plans).map((plan) => this.enrichPlan(plan));
   }

   /**
    * Gets current user subscription.
    *
    * @param userId - User ID.
    * @returns Active user subscription, or null.
    */
   async getMySubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      let subscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      if (subscription && this.isSubscriptionExpired(subscription.endDate)) {
         await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);
         subscription = null;
      }

      if (!subscription) {
         subscription = await this.subscribeToFreePlan(userId);
      }

      if (!subscription) {
         return null;
      }

      return {
         ...this.enrichUserSubscription(subscription),
         message: await this.buildSubscriptionMessage(subscription),
      };
   }

   /**
    * Gets user features.
    *
    * @param userId - User ID.
    * @returns User features, or null if not found.
    */
   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   /**
    * Subscribes user to a plan.
    *
    * @param userId - User ID.
    * @param planId - Subscription plan ID.
    * @returns Created user subscription.
    */
   async subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription> {
      const plan = await this.getRequiredActivePlan(planId);

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const startDate = new Date();
      const endDate = this.addDays(startDate, plan.durationDays);

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: {
            connect: {
               id: userId,
            },
         },
         plan: {
            connect: {
               id: planId,
            },
         },
         status: SubscriptionStatus.ACTIVE,
         startDate,
         endDate,
         willRenew: true,
      });

      await this.applyFeaturesForPlan(userId, plan);

      return this.enrichUserSubscription(subscription);
   }

   /**
    * Syncs user subscription with RevenueCat.
    *
    * @param userId - User ID.
    * @returns Synced user subscription, or null.
    */
   async syncSubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      const revenueCatData = await this.getRevenueCatSubscriberData(userId);
      const activeProduct = this.findActiveRevenueCatProduct(revenueCatData);

      if (!activeProduct) {
         return this.downgradeToFreePlan(userId);
      }

      const targetPlan = await this.subscriptionPlanRepository.findPlanByIdentifier(activeProduct.productIdentifier);

      if (!targetPlan) {
         throw new ApiError(404, `Plan mapping for product identifier '${activeProduct.productIdentifier}' not found on backend`);
      }

      const currentSubscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      const endDate = activeProduct.expiryTime ?? this.addDays(new Date(), DEFAULT_SUBSCRIPTION_DURATION_DAYS);

      if (!currentSubscription || currentSubscription.planId === freePlan?.id) {
         await this.activatePlan(userId, targetPlan.id, endDate, activeProduct.willRenew);
         return this.getMySubscription(userId);
      }

      if (currentSubscription.planId === targetPlan.id) {
         await this.userSubscriptionRepository.updateUserSubscription(currentSubscription.id, {
            endDate,
            willRenew: activeProduct.willRenew,
            nextPlanId: null,
         });

         return this.getMySubscription(userId);
      }

      const currentPlan = await this.subscriptionPlanRepository.getPlanById(currentSubscription.planId);

      if (!currentPlan) {
         throw new ApiError(404, "Current subscription plan not found");
      }

      if (targetPlan.price >= currentPlan.price) {
         await this.activatePlan(userId, targetPlan.id, endDate, activeProduct.willRenew);
      } else {
         await this.userSubscriptionRepository.updateUserSubscription(currentSubscription.id, {
            nextPlanId: targetPlan.id,
            willRenew: false,
         });
      }

      return this.getMySubscription(userId);
   }

   /**
    * Handles RevenueCat webhook.
    *
    * @param payload - RevenueCat webhook payload.
    * @param signatureHeader - Optional RevenueCat signature header.
    * @returns Nothing.
    */
   async handleWebhook(payload: Record<string, unknown>, _signatureHeader?: string): Promise<void> {
      const event = payload.event as RevenueCatWebhookEventData | undefined;

      if (!event) {
         return;
      }

      const userId = Number.parseInt(event.app_user_id, 10);

      if (Number.isNaN(userId)) {
         return;
      }

      const alreadyProcessed = await this.processedRevenueCatEventRepository.hasProcessedEvent(event.id);

      if (alreadyProcessed) {
         return;
      }

      await this.processedRevenueCatEventRepository.markEventProcessed(event.id, event.type);

      await this.handleRevenueCatEvent(userId, event.type);
   }

   /**
    * Applies plan features to user.
    *
    * @param userId - User ID.
    * @param plan - Subscription plan.
    * @returns Nothing.
    */
   private async applyFeaturesForPlan(userId: number, plan: EnrichedSubscriptionPlan): Promise<void> {
      const featurePayload = this.buildFeaturePayload(plan);

      const existingUserFeature = await this.userFeatureRepository.findByUserId(userId);

      if (existingUserFeature) {
         await this.userFeatureRepository.update(userId, featurePayload);
         return;
      }

      await this.userFeatureRepository.create({
         user: {
            connect: {
               id: userId,
            },
         },
         ...featurePayload,
      });
   }

   /**
    * Builds user feature payload from plan.
    *
    * @param plan - Subscription plan.
    * @returns User feature payload.
    */
   private buildFeaturePayload(plan: EnrichedSubscriptionPlan): FeatureLimitPayload {
      const limits: FeatureLimitPayload = {
         isProfileBlurEnabled: false,
         maxInterests: 0,
         maxVideoCallMinutes: 0,
         maxAudioCallMinutes: 0,
         maxMessages: 0,
         interests: 0,
         videoCallMinutes: 0,
         audioCallMinutes: 0,
         messages: 0,
      };

      for (const planFeature of plan.features) {
         const featureKey = planFeature.featureKey as FeatureKey;

         switch (featureKey) {
            case FeatureKey.PROFILE_BLUR:
               limits.isProfileBlurEnabled = planFeature.limit === "true";
               break;

            case FeatureKey.MAX_INTERESTS:
               limits.maxInterests = this.parseFeatureLimit(planFeature.limit);
               break;

            case FeatureKey.MAX_VIDEO_CALL_MINUTES:
               limits.maxVideoCallMinutes = this.parseFeatureLimit(planFeature.limit);
               break;

            case FeatureKey.MAX_AUDIO_CALL_MINUTES:
               limits.maxAudioCallMinutes = this.parseFeatureLimit(planFeature.limit);
               break;

            case FeatureKey.MAX_MESSAGES:
               limits.maxMessages = this.parseFeatureLimit(planFeature.limit);
               break;
         }
      }

      return limits;
   }

   /**
    * Gets RevenueCat subscriber data.
    *
    * @param userId - User ID.
    * @returns RevenueCat subscriber data.
    */
   private async getRevenueCatSubscriberData(userId: number): Promise<RevenueCatSubscriberResponse> {
      const apiKey = process.env.REVENUECAT_SECRET_API_KEY;

      if (!apiKey) {
         throw new ApiError(500, "RevenueCat API key is not configured on backend");
      }

      const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${userId}`, {
         method: "GET",
         headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
         },
      });

      if (!response.ok) {
         throw new ApiError(response.status, `Failed to retrieve subscriber info from RevenueCat: ${response.statusText}`);
      }

      const data = (await response.json()) as RevenueCatSubscriberResponse;

      if (!data.subscriber) {
         throw new ApiError(500, "Subscriber data not found in RevenueCat response");
      }

      return data;
   }

   /**
    * Finds active RevenueCat product.
    *
    * @param data - RevenueCat subscriber data.
    * @returns Active product data, or null.
    */
   private findActiveRevenueCatProduct(data: RevenueCatSubscriberResponse): {
      productIdentifier: string;
      expiryTime: Date | null;
      willRenew: boolean;
   } | null {
      const subscriptions = data.subscriber?.subscriptions ?? {};

      for (const [productIdentifier, subscription] of Object.entries(subscriptions)) {
         const expiryTime = subscription.expires_date ? new Date(subscription.expires_date) : null;

         if (expiryTime && expiryTime <= new Date()) {
            continue;
         }

         return {
            productIdentifier,
            expiryTime,
            willRenew: !subscription.unsubscribe_detected_at,
         };
      }

      return null;
   }

   /**
    * Handles RevenueCat event by type.
    *
    * @param userId - User ID.
    * @param eventType - RevenueCat event type.
    * @returns Nothing.
    */
   private async handleRevenueCatEvent(userId: number, eventType: RevenueCatWebhookEvent): Promise<void> {
      switch (eventType) {
         case RevenueCatWebhookEvent.INITIAL_PURCHASE:
         case RevenueCatWebhookEvent.RENEWAL:
         case RevenueCatWebhookEvent.UNCANCELLATION:
         case RevenueCatWebhookEvent.PRODUCT_CHANGE:
            await this.syncSubscription(userId);
            return;

         case RevenueCatWebhookEvent.CANCELLATION:
            await this.cancelRenewal(userId);
            return;

         case RevenueCatWebhookEvent.EXPIRATION:
            await this.downgradeToFreePlan(userId);
            return;

         case RevenueCatWebhookEvent.REFUND:
            await this.handleRefund(userId);
            return;

         case RevenueCatWebhookEvent.BILLING_ISSUE:
            return;
      }
   }

   /**
    * Cancels active subscription renewal.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   private async cancelRenewal(userId: number): Promise<void> {
      const activeSubscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      if (!activeSubscription) {
         return;
      }

      await this.userSubscriptionRepository.updateUserSubscription(activeSubscription.id, {
         willRenew: false,
      });
   }

   /**
    * Handles RevenueCat refund.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   private async handleRefund(userId: number): Promise<void> {
      const freeSubscription = await this.downgradeToFreePlan(userId);

      if (!freeSubscription) {
         return;
      }

      await this.userSubscriptionRepository.updateUserSubscription(freeSubscription.id, {
         status: SubscriptionStatus.INACTIVE,
      });
   }

   /**
    * Downgrades user to FREE plan.
    *
    * @param userId - User ID.
    * @returns FREE user subscription.
    */
   private async downgradeToFreePlan(userId: number): Promise<EnrichedUserSubscription | null> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         throw new ApiError(500, "FREE plan not found in database");
      }

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      return this.subscribe(userId, freePlan.id);
   }

   /**
    * Subscribes user to FREE plan if available.
    *
    * @param userId - User ID.
    * @returns FREE user subscription, or null.
    */
   private async subscribeToFreePlan(userId: number): Promise<EnrichedUserSubscription | null> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         return null;
      }

      return this.subscribe(userId, freePlan.id);
   }

   /**
    * Activates a subscription plan.
    *
    * @param userId - User ID.
    * @param planId - Plan ID.
    * @param endDate - Subscription end date.
    * @param willRenew - Renewal status.
    * @returns Nothing.
    */
   private async activatePlan(userId: number, planId: number, endDate: Date, willRenew: boolean): Promise<void> {
      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: {
            connect: {
               id: userId,
            },
         },
         plan: {
            connect: {
               id: planId,
            },
         },
         status: SubscriptionStatus.ACTIVE,
         startDate: new Date(),
         endDate,
         willRenew,
      });

      await this.applyFeaturesForPlan(userId, subscription.plan);
   }

   /**
    * Gets required active plan.
    *
    * @param planId - Plan ID.
    * @returns Active subscription plan.
    */
   private async getRequiredActivePlan(planId: number): Promise<EnrichedSubscriptionPlan> {
      const plan = await this.subscriptionPlanRepository.getPlanById(planId);

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found");
      }

      if (!plan.isActive) {
         throw new ApiError(400, "This subscription plan is no longer active");
      }

      return this.enrichPlan(plan);
   }

   /**
    * Builds subscription status message.
    *
    * @param subscription - User subscription.
    * @returns Subscription message.
    */
   private async buildSubscriptionMessage(subscription: EnrichedUserSubscription): Promise<string> {
      const endDate = new Date(subscription.endDate).toLocaleDateString();

      if (subscription.status !== SubscriptionStatus.ACTIVE) {
         return "Your subscription is currently inactive.";
      }

      if (subscription.nextPlanId) {
         const nextPlan = await this.subscriptionPlanRepository.getPlanById(subscription.nextPlanId);

         if (!nextPlan) {
            return `Your plan will change on ${endDate}`;
         }

         const currentPrice = subscription.plan?.price ?? 0;
         const action = nextPlan.price < currentPrice ? "downgrade" : "change";

         return `Your plan will ${action} to ${nextPlan.name} on ${endDate}`;
      }

      if (!subscription.willRenew) {
         return `Your plan has been cancelled and will expire on ${endDate}`;
      }

      return `Your plan is active and will renew on ${endDate}`;
   }

   /**
    * Enriches user subscription.
    *
    * @param subscription - User subscription.
    * @returns Enriched user subscription.
    */
   private enrichUserSubscription(subscription: EnrichedUserSubscription): EnrichedUserSubscription {
      return {
         ...subscription,
         plan: this.enrichPlan(subscription.plan),
      };
   }

   /**
    * Enriches subscription plan.
    *
    * @param plan - Subscription plan.
    * @returns Enriched subscription plan.
    */
   private enrichPlan(plan: EnrichedSubscriptionPlan): EnrichedSubscriptionPlan {
      return {
         ...plan,
         features: plan.features.map((planFeature) => {
            const feature = SYSTEM_FEATURES.find((systemFeature) => systemFeature.key === planFeature.featureKey);

            return {
               ...planFeature,
               description: planFeature.description || feature?.description || null,
               feature,
            };
         }),
      };
   }

   /**
    * Sorts subscription plans.
    *
    * @param plans - Subscription plans.
    * @returns Sorted subscription plans.
    */
   private sortPlans(plans: EnrichedSubscriptionPlan[]): EnrichedSubscriptionPlan[] {
      return [...plans].sort((firstPlan, secondPlan) => {
         if (firstPlan.name === FREE_PLAN_NAME) {
            return -1;
         }

         if (secondPlan.name === FREE_PLAN_NAME) {
            return 1;
         }

         return firstPlan.price - secondPlan.price;
      });
   }

   /**
    * Checks if subscription is expired.
    *
    * @param endDate - Subscription end date.
    * @returns True if subscription expired.
    */
   private isSubscriptionExpired(endDate: Date): boolean {
      return new Date() > endDate;
   }

   /**
    * Adds days to date.
    *
    * @param date - Start date.
    * @param days - Days to add.
    * @returns New date.
    */
   private addDays(date: Date, days: number): Date {
      return new Date(date.getTime() + days * MS_PER_DAY);
   }

   /**
    * Parses feature limit.
    *
    * @param value - Feature limit value.
    * @returns Parsed number.
    */
   private parseFeatureLimit(value: string): number {
      const parsedValue = Number.parseInt(value, 10);

      return Number.isNaN(parsedValue) ? 0 : parsedValue;
   }
}
