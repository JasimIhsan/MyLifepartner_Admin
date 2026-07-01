import { ISubscriptionRepository } from "@/interfaces/repositories/subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { EnrichedSubscriptionPlan, EnrichedUserSubscription, IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { UserFeature, SubscriptionStatus } from "@prisma/client";
import { SYSTEM_FEATURES } from "../../constants/SYSTEM_FEATURES";
import { FeatureKey } from "../../enums/feature-key.enum";
import { RevenueCatWebhookEvent } from "../../enums/revenuecat-event.enum";

export class UserSubscriptionService implements IUserSubscriptionService {
   constructor(
      private subscriptionRepository: ISubscriptionRepository,
      private userFeatureRepository: IUserFeatureRepository
   ) {}

   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionRepository.getAllPlansWithFeatures();

      // Ensure FREE plan is always first, then sort by price
      const sortedPlans = [...plans].sort((a, b) => {
         if (a.name === "FREE") return -1;
         if (b.name === "FREE") return 1;
         return a.price - b.price;
      });

      return sortedPlans.map((plan) => ({
         ...plan,
         features: plan.features.map((pf) => {
            const feature = SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey);
            return {
               ...pf,
               description: pf.description || feature?.description,
               feature,
            };
         }),
      })) as EnrichedSubscriptionPlan[];
   }

   async getMySubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      let sub = await this.subscriptionRepository.findActiveSubscriptionByUserId(userId);

      // If subscription exists but is expired, deactivate it
      if (sub && new Date() > sub.endDate) {
         await this.subscriptionRepository.deactivateUserSubscriptions(userId);
         sub = null;
      }

      // If no active subscription, fallback to FREE plan
      if (!sub) {
         const freePlan = await this.subscriptionRepository.getPlanByName("FREE");
         if (freePlan) {
            sub = (await this.subscribe(userId, freePlan.id)) as any;
         }
      }

      if (!sub) return null;

      // Add descriptive text message for UI details
      let message = "";
      if (sub.status !== SubscriptionStatus.ACTIVE) {
         message = "Your subscription is currently inactive.";
      } else if (sub.nextPlanId) {
         const nextPlan = await this.subscriptionRepository.getPlanById(sub.nextPlanId);
         if (nextPlan) {
            const currentPlanPrice = sub.plan?.price || 0;
            const action = nextPlan.price < currentPlanPrice ? "downgrade" : "change";
            message = `Your plan will ${action} to ${nextPlan.name} on ${new Date(sub.endDate).toLocaleDateString()}`;
         } else {
            message = `Your plan will change on ${new Date(sub.endDate).toLocaleDateString()}`;
         }
      } else if (!sub.willRenew) {
         message = `Your plan has been cancelled and will expire on ${new Date(sub.endDate).toLocaleDateString()}`;
      } else {
         message = `Your plan is active and will renew on ${new Date(sub.endDate).toLocaleDateString()}`;
      }

      return {
         ...sub,
         message,
         plan: {
            ...sub.plan,
            features: sub.plan.features.map((pf) => {
               const feature = SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey);
               return {
                  ...pf,
                  description: pf.description || feature?.description,
                  feature,
               };
            }),
         },
      } as any;
   }

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return await this.userFeatureRepository.findByUserId(userId);
   }

   async subscribe(userId: number, planId: number): Promise<EnrichedUserSubscription> {
      const plan = await this.subscriptionRepository.getPlanById(planId);

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found");
      }

      if (!plan.isActive) {
         throw new ApiError(400, "This subscription plan is no longer active");
      }

      // Deactivate any existing active subscriptions
      await this.subscriptionRepository.deactivateUserSubscriptions(userId);

      // Create new subscription
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + plan.durationDays);

      const userSubscription = await this.subscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: SubscriptionStatus.ACTIVE,
         startDate,
         endDate,
         willRenew: true,
      });

      await this.applyFeaturesForPlan(userId, plan);

      const enrichedSubscription = {
         ...userSubscription,
         plan: {
            ...userSubscription.plan,
            features: userSubscription.plan.features.map((pf) => {
               const feature = SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey);
               return {
                  ...pf,
                  description: pf.description || feature?.description,
                  feature,
               };
            }),
         },
      };

      return enrichedSubscription as EnrichedUserSubscription;
   }

   private async applyFeaturesForPlan(userId: number, plan: any) {
      // Map plan features to fixed columns
      const newLimits = {
         isProfileBlurEnabled: false,
         maxInterests: 0,
         maxVideoCallMinutes: 0,
         maxAudioCallMinutes: 0,
         maxMessages: 0,
      };

      for (const pf of plan.features) {
         const key = pf.featureKey as FeatureKey;
         const valStr = pf.limit;

         if (key === FeatureKey.PROFILE_BLUR) newLimits.isProfileBlurEnabled = valStr === "true";

         if (key === FeatureKey.MAX_INTERESTS) newLimits.maxInterests = parseInt(valStr) || 0;
         if (key === FeatureKey.MAX_VIDEO_CALL_MINUTES) newLimits.maxVideoCallMinutes = parseInt(valStr) || 0;
         if (key === FeatureKey.MAX_AUDIO_CALL_MINUTES) newLimits.maxAudioCallMinutes = parseInt(valStr) || 0;
         if (key === FeatureKey.MAX_MESSAGES) newLimits.maxMessages = parseInt(valStr) || 0;
      }

      const existingUserFeature = await this.userFeatureRepository.findByUserId(userId);

      const featurePayload = {
         isProfileBlurEnabled: newLimits.isProfileBlurEnabled,

         maxInterests: newLimits.maxInterests,
         maxVideoCallMinutes: newLimits.maxVideoCallMinutes,
         maxAudioCallMinutes: newLimits.maxAudioCallMinutes,
         maxMessages: newLimits.maxMessages,

         // Reset usage when changing plan
         interests: 0,
         videoCallMinutes: 0,
         audioCallMinutes: 0,
         messages: 0,
      };

      if (existingUserFeature) {
         await this.userFeatureRepository.update(userId, featurePayload);
      } else {
         await this.userFeatureRepository.create({
            user: { connect: { id: userId } },
            ...featurePayload,
         });
      }
   }

   async syncSubscription(userId: number): Promise<any> {
      const apiKey = process.env.REVENUECAT_SECRET_API_KEY;
      if (!apiKey) {
         throw new ApiError(500, "RevenueCat API key is not configured on backend");
      }

      const response = await fetch(`https://api.revenuecat.com/v1/subscribers/${userId}`, {
         method: "GET",
         headers: {
            "Authorization": `Bearer ${apiKey}`,
            "Content-Type": "application/json",
         },
      });

      if (!response.ok) {
         throw new ApiError(response.status, `Failed to retrieve subscriber info from RevenueCat: ${response.statusText}`);
      }

      const rcData: any = await response.json();
      const subscriber = rcData.subscriber;
      if (!subscriber) {
         throw new ApiError(500, "Subscriber data not found in RevenueCat response");
      }

      // Check active subscriptions in RevenueCat
      const activeSubscriptions = subscriber.subscriptions || {};
      let activeProductIdentifier: string | null = null;
      let expiryTime: string | null = null;
      let willRenew = true;

      for (const [prodId, subInfo] of Object.entries(activeSubscriptions) as any) {
         const expiresDate = subInfo.expires_date ? new Date(subInfo.expires_date) : null;
         const unsubscribeDetected = !!subInfo.unsubscribe_detected_at;
         if (!expiresDate || expiresDate > new Date()) {
            activeProductIdentifier = prodId;
            expiryTime = subInfo.expires_date;
            willRenew = !unsubscribeDetected;
            break;
         }
      }

      if (!activeProductIdentifier) {
         // Fallback/Downgrade to FREE
         const freePlan = await this.subscriptionRepository.getPlanByName("FREE");
         if (!freePlan) {
            throw new ApiError(500, "FREE plan not found in database");
         }
         await this.subscriptionRepository.deactivateUserSubscriptions(userId);
         const sub = await this.subscribe(userId, freePlan.id);
         return sub;
      }

      // Find the plan mapping dynamically using the RevenueCat identifier
      const targetPlan = await this.subscriptionRepository.findPlanByIdentifier(activeProductIdentifier);
      if (!targetPlan) {
         throw new ApiError(404, `Plan mapping for product identifier '${activeProductIdentifier}' not found on backend`);
      }

      const currentSub = await this.subscriptionRepository.findActiveSubscriptionByUserId(userId);
      const endsAt = expiryTime ? new Date(expiryTime) : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

      if (!currentSub || currentSub.planId === (await this.subscriptionRepository.getPlanByName("FREE"))?.id) {
         // Immediate Upgrade / Initial activation
         await this.subscriptionRepository.deactivateUserSubscriptions(userId);
         const newSub = await this.subscriptionRepository.createUserSubscription({
            user: { connect: { id: userId } },
            plan: { connect: { id: targetPlan.id } },
            status: SubscriptionStatus.ACTIVE,
            startDate: new Date(),
            endDate: endsAt,
            willRenew,
         });
         await this.applyFeaturesForPlan(userId, targetPlan);
         return this.getMySubscription(userId);
      }

      // If already active plan, see if it is a change
      if (currentSub.planId !== targetPlan.id) {
         // Check pricing/levels or dynamic upgrades
         const currentPlan = await this.subscriptionRepository.getPlanById(currentSub.planId);
         if (currentPlan) {
            if (targetPlan.price >= currentPlan.price) {
               // Immediate upgrade
               await this.subscriptionRepository.deactivateUserSubscriptions(userId);
               const newSub = await this.subscriptionRepository.createUserSubscription({
                  user: { connect: { id: userId } },
                  plan: { connect: { id: targetPlan.id } },
                  status: SubscriptionStatus.ACTIVE,
                  startDate: new Date(),
                  endDate: endsAt,
                  willRenew,
               });
               await this.applyFeaturesForPlan(userId, targetPlan);
            } else {
               // Scheduled downgrade
               await this.subscriptionRepository.updateUserSubscription(currentSub.id, {
                  nextPlanId: targetPlan.id,
                  willRenew: false, // Don't auto-renew the old high plan
               });
            }
         }
      } else {
         // Renewal / date / willRenew updates
         await this.subscriptionRepository.updateUserSubscription(currentSub.id, {
            endDate: endsAt,
            willRenew,
            nextPlanId: null, // Clear any pending downgrade if they renewed the same plan
         });
      }

      return this.getMySubscription(userId);
   }

   async handleWebhook(payload: any, signatureHeader?: string): Promise<void> {
      // Validate signature
      const webhookSecret = process.env.REVENUECAT_WEBHOOK_SECRET;
      if (webhookSecret && signatureHeader) {
         // Validation checks can be added here.
      }

      const event = payload.event;
      if (!event) return;

      const eventId = event.id;
      const eventType = event.type as RevenueCatWebhookEvent;
      const appUserId = parseInt(event.app_user_id);

      if (isNaN(appUserId)) {
         return; // Skip if app_user_id is not matching our user ID scheme
      }

      // Idempotency check
      const alreadyProcessed = await this.subscriptionRepository.hasProcessedEvent(eventId);
      if (alreadyProcessed) {
         return;
      }

      // Save processed event ID
      await this.subscriptionRepository.markEventProcessed(eventId, eventType);

      // Handle specific webhook actions
      switch (eventType) {
         case RevenueCatWebhookEvent.INITIAL_PURCHASE:
         case RevenueCatWebhookEvent.RENEWAL:
         case RevenueCatWebhookEvent.UNCANCELLATION:
         case RevenueCatWebhookEvent.PRODUCT_CHANGE:
            await this.syncSubscription(appUserId);
            break;

         case RevenueCatWebhookEvent.CANCELLATION:
            const activeSub = await this.subscriptionRepository.findActiveSubscriptionByUserId(appUserId);
            if (activeSub) {
               await this.subscriptionRepository.updateUserSubscription(activeSub.id, {
                  willRenew: false,
               });
            }
            break;

         case RevenueCatWebhookEvent.EXPIRATION:
            const freePlan = await this.subscriptionRepository.getPlanByName("FREE");
            if (freePlan) {
               await this.subscriptionRepository.deactivateUserSubscriptions(appUserId);
               await this.subscribe(appUserId, freePlan.id);
            }
            break;

         case RevenueCatWebhookEvent.REFUND:
            const freePlanRefund = await this.subscriptionRepository.getPlanByName("FREE");
            if (freePlanRefund) {
               await this.subscriptionRepository.deactivateUserSubscriptions(appUserId);
               const sub = await this.subscribe(appUserId, freePlanRefund.id);
               await this.subscriptionRepository.updateUserSubscription(sub.id, {
                  status: SubscriptionStatus.INACTIVE, // mark refunded plan details accordingly
               });
            }
            break;

         case RevenueCatWebhookEvent.BILLING_ISSUE:
            // Keep plan active or trigger user communication, but don't remove access immediately until EXPIRATION
            break;
      }
   }
}
