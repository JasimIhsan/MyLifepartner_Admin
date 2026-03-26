import { IUserSubscriptionService, EnrichedSubscriptionPlan, EnrichedUserSubscription } from "@/interfaces/services/user.subscription.service.interface";
import { ISubscriptionRepository } from "@/interfaces/repositories/subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { UserFeature } from "@prisma/client";
import { ApiError } from "@/utils/ApiError";
import { SYSTEM_FEATURES } from "../admin/admin.feature.service";

export class UserSubscriptionService implements IUserSubscriptionService {
   constructor(
      private subscriptionRepository: ISubscriptionRepository,
      private userFeatureRepository: IUserFeatureRepository
   ) {}

   async getPlans(): Promise<EnrichedSubscriptionPlan[]> {
      const plans = await this.subscriptionRepository.getAllPlansWithFeatures();
      return plans.map((plan) => ({
         ...plan,
         features: plan.features.map((pf) => ({
            ...pf,
            feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
         })),
      })) as EnrichedSubscriptionPlan[];
   }

   async getMySubscription(userId: number): Promise<EnrichedUserSubscription | null> {
      const sub = await this.subscriptionRepository.findActiveSubscriptionByUserId(userId);
      if (!sub) return null;

      return {
         ...sub,
         plan: {
            ...sub.plan,
            features: sub.plan.features.map((pf) => ({
               ...pf,
               feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
            })),
         },
      } as EnrichedUserSubscription;
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

      // Deactivate any existing active subscriptions for this user
      await this.subscriptionRepository.deactivateUserSubscriptions(userId);

      // Calculate end date based on durationDays
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + plan.durationDays);

      const userSubscription = await this.subscriptionRepository.createUserSubscription({
         user: { connect: { id: userId } },
         plan: { connect: { id: planId } },
         status: "ACTIVE",
         startDate,
         endDate,
      });

      // ─── Map Dynamic Features to Fixed Columns ───────────────────────────
      const newLimits = {
         canAudioCall: false,
         canVideoCall: false,
         canSendMessage: false,
         isProfileBlurEnabled: false,
         maxInterests: 0,
         maxVideoCallMinutes: 0,
         maxAudioCallMinutes: 0,
         maxMessages: 0,
      };

      for (const pf of plan.features) {
         const key = pf.featureKey;
         const valStr = pf.limit;

         if (key === "audio_call") newLimits.canAudioCall = valStr === "true";
         if (key === "video_call") newLimits.canVideoCall = valStr === "true";
         if (key === "send_message") newLimits.canSendMessage = valStr === "true";
         if (key === "profile_blur") newLimits.isProfileBlurEnabled = valStr === "true";

         if (key === "max_interests") newLimits.maxInterests = parseInt(valStr) || 0;
         if (key === "max_video_call_minutes") newLimits.maxVideoCallMinutes = parseInt(valStr) || 0;
         if (key === "max_audio_call_minutes") newLimits.maxAudioCallMinutes = parseInt(valStr) || 0;
         if (key === "max_messages") newLimits.maxMessages = parseInt(valStr) || 0;
      }

      const existingUserFeature = await this.userFeatureRepository.findByUserId(userId);

      let newRemainingInterests = newLimits.maxInterests;
      let newRemainingVideoCall = newLimits.maxVideoCallMinutes;
      let newRemainingAudioCall = newLimits.maxAudioCallMinutes;
      let newRemainingMessages = newLimits.maxMessages;

      if (existingUserFeature) {
         const calcRemaining = (oldRemaining: number, oldMax: number, newMax: number) => {
            if (newMax > oldMax) return oldRemaining + (newMax - oldMax); // Upgrade
            return Math.min(oldRemaining, newMax); // Downgrade
         };

         newRemainingInterests = calcRemaining(existingUserFeature.remainingInterests, existingUserFeature.maxInterests, newLimits.maxInterests);
         newRemainingVideoCall = calcRemaining(existingUserFeature.remainingVideoCallMinutes, existingUserFeature.maxVideoCallMinutes, newLimits.maxVideoCallMinutes);
         newRemainingAudioCall = calcRemaining(existingUserFeature.remainingAudioCallMinutes, existingUserFeature.maxAudioCallMinutes, newLimits.maxAudioCallMinutes);
         newRemainingMessages = calcRemaining(existingUserFeature.remainingMessages, existingUserFeature.maxMessages, newLimits.maxMessages);
      }

      await this.userFeatureRepository.update(userId, {
         canAudioCall: newLimits.canAudioCall,
         canVideoCall: newLimits.canVideoCall,
         canSendMessage: newLimits.canSendMessage,
         isProfileBlurEnabled: newLimits.isProfileBlurEnabled,
         maxInterests: newLimits.maxInterests,
         maxVideoCallMinutes: newLimits.maxVideoCallMinutes,
         maxAudioCallMinutes: newLimits.maxAudioCallMinutes,
         maxMessages: newLimits.maxMessages,
         remainingInterests: newRemainingInterests,
         remainingVideoCallMinutes: newRemainingVideoCall,
         remainingAudioCallMinutes: newRemainingAudioCall,
         remainingMessages: newRemainingMessages,
      });

      const enrichedSubscription = {
         ...userSubscription,
         plan: {
            ...userSubscription.plan,
            features: userSubscription.plan.features.map((pf) => ({
               ...pf,
               feature: SYSTEM_FEATURES.find((sf) => sf.key === pf.featureKey),
            })),
         },
      };

      return enrichedSubscription as EnrichedUserSubscription;
   }
}

