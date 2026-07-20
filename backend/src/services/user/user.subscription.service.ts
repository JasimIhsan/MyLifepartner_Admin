import prisma from "@/config/prisma";
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
import logger from "@/utils/logger";

type RevenueCatSubscription = {
   expires_date?: string;
   purchase_date?: string;
   unsubscribe_detected_at?: string;
};

type RevenueCatSubscriberResponse = {
   subscriber?: {
      original_app_user_id?: string;
      aliases?: string[];
      subscriptions?: Record<string, RevenueCatSubscription>;
   };
};

type RevenueCatWebhookEventData = {
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
const PURCHASE_SYNC_GRACE_PERIOD_MS = 2 * 60 * 1000; // 2 minutes

export class UserSubscriptionService implements IUserSubscriptionService {
   constructor(
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly userSubscriptionRepository: IUserSubscriptionRepository,
      private readonly processedRevenueCatEventRepository: IProcessedRevenueCatEventRepository,
      private readonly userFeatureRepository: IUserFeatureRepository
   ) {}

   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionPlanRepository.getAllPlansWithFeatures();
      return this.sortPlans(plans).map((plan) => this.enrichPlan(plan));
   }

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

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   async subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription> {
      const plan = await this.getRequiredActivePlan(planId);
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      const currentSubscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);

      if (currentSubscription) {
         if (!currentSubscription.willRenew && planId === freePlan?.id) {
            throw new ApiError(400, "Your plan is already cancelled and will downgrade on expiration.");
         }
      }

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const startDate = new Date();
      const endDate = this.addDays(startDate, plan.durationDays);

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: SubscriptionStatus.ACTIVE,
         startDate,
         endDate,
         willRenew: true,
      });

      await this.applyFeaturesForPlan(userId, plan);

      return this.enrichUserSubscription(subscription);
   }

   async syncSubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      const revenueCatData = await this.getRevenueCatSubscriberData(userId);

      const originalUserIdStr = revenueCatData.subscriber?.original_app_user_id;
      const aliases = revenueCatData.subscriber?.aliases || [];
      const userIdStr = userId.toString();

      if (originalUserIdStr !== userIdStr && !aliases.includes(userIdStr)) {
         throw new ApiError(409, "RevenueCat subscriber identity does not match authenticated user.");
      }

      const activeProduct = this.findActiveRevenueCatProduct(revenueCatData);
      const currentSubscription = await this.userSubscriptionRepository.findActiveSubscriptionByUserId(userId);
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!activeProduct) {
         if (currentSubscription && currentSubscription.planId !== freePlan?.id) {
            const timeSinceCreated = new Date().getTime() - currentSubscription.createdAt.getTime();
            if (timeSinceCreated < PURCHASE_SYNC_GRACE_PERIOD_MS) {
               return this.getMySubscription(userId);
            }
         }
         return this.downgradeToFreePlan(userId);
      }

      const targetPlan = await this.subscriptionPlanRepository.findPlanByIdentifier(activeProduct.productIdentifier);

      if (!targetPlan) {
         throw new ApiError(404, `Plan mapping for product identifier '${activeProduct.productIdentifier}' not found on backend`);
      }

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

   async handleWebhook(payload: Record<string, unknown>, _signatureHeader?: string): Promise<void> {
      const event = payload.event as RevenueCatWebhookEventData | undefined;

      logger.info("👉👉👉 WEBHOOK EVENT: ", event);

      if (!event) {
         return;
      }

      let userId: number | undefined;

      // Attempt to resolve the true user identity from RevenueCat's identifiers
      const potentialIds = [event.original_app_user_id, event.app_user_id, ...(event.aliases || [])];

      for (const idStr of potentialIds) {
         if (!idStr) continue;
         const parsed = Number.parseInt(idStr, 10);
         if (!Number.isNaN(parsed) && parsed > 0) {
            userId = parsed;
            break; // Found the primary integer user ID
         }
      }

      if (userId === undefined) {
         logger.warn("Could not resolve valid integer userId from RevenueCat event", event);
         return;
      }

      const alreadyProcessed = await this.processedRevenueCatEventRepository.hasProcessedEvent(event.id);

      if (alreadyProcessed) {
         return;
      }

      await this.handleRevenueCatEvent(userId, event);
      await this.processedRevenueCatEventRepository.markEventProcessed(event.id, event.type);
   }

   private async handleRevenueCatEvent(userId: number, event: RevenueCatWebhookEventData): Promise<void> {
      const targetPlanId = await this.resolveTargetPlanId(event);

      await prisma.$transaction(async (tx) => {
         const currentSubscription = await tx.userSubscription.findFirst({
            where: { userId, status: "ACTIVE" },
            include: { plan: true },
            orderBy: { createdAt: "desc" },
         });

         const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

         switch (event.type) {
            case RevenueCatWebhookEvent.INITIAL_PURCHASE:
            case RevenueCatWebhookEvent.RENEWAL:
            case RevenueCatWebhookEvent.UNCANCELLATION:
            case RevenueCatWebhookEvent.PRODUCT_CHANGE: {
               if (!targetPlanId) {
                  // Fallback to sync if plan couldn't be resolved via event data directly
                  await this.syncSubscription(userId);
                  return;
               }

               const endDate = event.expiration_at_ms ? new Date(event.expiration_at_ms) : this.addDays(new Date(), DEFAULT_SUBSCRIPTION_DURATION_DAYS);

               if (currentSubscription && currentSubscription.planId !== targetPlanId && currentSubscription.planId !== freePlan?.id) {
                  if (event.type === RevenueCatWebhookEvent.PRODUCT_CHANGE) {
                     const newPlan = await tx.subscriptionPlan.findUnique({ where: { id: targetPlanId } });
                     if (newPlan && newPlan.price < currentSubscription.plan.price) {
                        await tx.userSubscription.update({
                           where: { id: currentSubscription.id },
                           data: { nextPlanId: targetPlanId, willRenew: false },
                        });
                        return;
                     }
                  }
               }

               await tx.userSubscription.updateMany({
                  where: { userId, status: "ACTIVE" },
                  data: { status: "EXPIRED" },
               });

               const originalTransactionId = event.original_transaction_id;

               let subscription;

               if (originalTransactionId) {
                  subscription = await tx.userSubscription.upsert({
                     where: { originalTransactionId },
                     create: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        startDate: new Date(),
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        originalTransactionId,
                        store: event.store,
                        environment: event.environment,
                     },
                     update: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        store: event.store,
                        environment: event.environment,
                     },
                     include: { plan: { include: { features: true } } },
                  });
               } else {
                  subscription = await tx.userSubscription.create({
                     data: {
                        userId,
                        planId: targetPlanId,
                        status: "ACTIVE",
                        startDate: new Date(),
                        endDate,
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        originalTransactionId: null,
                        store: event.store,
                        environment: event.environment,
                     },
                     include: { plan: { include: { features: true } } },
                  });
               }

               const featurePayload = this.buildFeaturePayload(subscription.plan as EnrichedSubscriptionPlan);

               const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
               if (existingFeatures) {
                  await tx.userFeature.update({ where: { userId }, data: featurePayload });
               } else {
                  await tx.userFeature.create({ data: { userId, ...featurePayload } });
               }

               break;
            }

            case RevenueCatWebhookEvent.CANCELLATION: {
               if (currentSubscription) {
                  await tx.userSubscription.update({
                     where: { id: currentSubscription.id },
                     data: { willRenew: false, lastEventTimestampMs: event.event_timestamp_ms, revenueCatEventId: event.id },
                  });
               }
               break;
            }

            case RevenueCatWebhookEvent.EXPIRATION:
            case RevenueCatWebhookEvent.REFUND: {
               await tx.userSubscription.updateMany({
                  where: { userId, status: "ACTIVE" },
                  data: { status: "EXPIRED" },
               });
               if (freePlan) {
                  const subscription = await tx.userSubscription.create({
                     data: {
                        userId,
                        planId: freePlan.id,
                        status: "ACTIVE",
                        startDate: new Date(),
                        endDate: this.addDays(new Date(), DEFAULT_SUBSCRIPTION_DURATION_DAYS),
                        willRenew: true,
                        revenueCatEventId: event.id,
                        lastEventTimestampMs: event.event_timestamp_ms,
                        originalTransactionId: null,
                     },
                     include: { plan: { include: { features: true } } },
                  });
                  const featurePayload = this.buildFeaturePayload(subscription.plan as EnrichedSubscriptionPlan);
                  const existingFeatures = await tx.userFeature.findUnique({ where: { userId } });
                  if (existingFeatures) {
                     await tx.userFeature.update({ where: { userId }, data: featurePayload });
                  } else {
                     await tx.userFeature.create({ data: { userId, ...featurePayload } });
                  }
               }
               break;
            }
         }
      });
   }

   private async resolveTargetPlanId(event: RevenueCatWebhookEventData): Promise<number | null> {
      let identifier = event.product_id;
      if (!identifier && event.entitlement_ids && event.entitlement_ids.length > 0) {
         // Default logic assuming mapping is equal or something
      }
      if (identifier) {
         const plan = await this.subscriptionPlanRepository.findPlanByIdentifier(identifier);
         if (plan) return plan.id;
      }
      return null;
   }

   private async applyFeaturesForPlan(userId: number, plan: EnrichedSubscriptionPlan): Promise<void> {
      const featurePayload = this.buildFeaturePayload(plan);

      const existingUserFeature = await this.userFeatureRepository.findByUserId(userId);

      if (existingUserFeature) {
         await this.userFeatureRepository.update(userId, featurePayload);
         return;
      }

      await this.userFeatureRepository.create({
         user: { connect: { id: userId } },
         ...featurePayload,
      });
   }

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

   private async downgradeToFreePlan(userId: number): Promise<EnrichedUserSubscription | null> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         throw new ApiError(500, "FREE plan not found in database");
      }

      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      return this.subscribe(userId, freePlan.id);
   }

   private async subscribeToFreePlan(userId: number): Promise<EnrichedUserSubscription | null> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         return null;
      }

      return this.subscribe(userId, freePlan.id);
   }

   private async activatePlan(userId: number, planId: number, endDate: Date, willRenew: boolean): Promise<void> {
      await this.userSubscriptionRepository.deactivateUserSubscriptions(userId);

      const subscription = await this.userSubscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: SubscriptionStatus.ACTIVE,
         startDate: new Date(),
         endDate,
         willRenew,
      });

      await this.applyFeaturesForPlan(userId, subscription.plan);
   }

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

   private enrichUserSubscription(subscription: EnrichedUserSubscription): EnrichedUserSubscription {
      return {
         ...subscription,
         plan: this.enrichPlan(subscription.plan),
      };
   }

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

   private isSubscriptionExpired(endDate: Date): boolean {
      return new Date() > endDate;
   }

   private addDays(date: Date, days: number): Date {
      return new Date(date.getTime() + days * MS_PER_DAY);
   }

   private parseFeatureLimit(value: string): number {
      const parsedValue = Number.parseInt(value, 10);
      return Number.isNaN(parsedValue) ? 0 : parsedValue;
   }
}
