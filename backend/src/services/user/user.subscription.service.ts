import { ISubscriptionRepository } from "@/interfaces/repositories/subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { EnrichedSubscriptionPlan, EnrichedUserSubscription, IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { UserFeature } from "@prisma/client";
import { SYSTEM_FEATURES } from "../../constants/SYSTEM_FEATURES";
import { FeatureKey } from "../../enums/feature-key.enum";

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

      return {
         ...sub,
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

      // Deactivate any existing active subscriptions
      await this.subscriptionRepository.deactivateUserSubscriptions(userId);

      // Create new subscription
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
}
