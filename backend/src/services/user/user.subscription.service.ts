import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import prisma from "@/config/prisma";
import { SubscriptionPlan, UserSubscription, UserFeature } from "@prisma/client";
import { ApiError } from "@/utils/ApiError";

export class UserSubscriptionService implements IUserSubscriptionService {
   async getPlans(): Promise<SubscriptionPlan[]> {
      // Find all active plans, including features
      return await prisma.subscriptionPlan.findMany({
         where: { isActive: true },
         include: { features: { include: { feature: true } } },
         orderBy: { price: "asc" },
      });
   }

   async getMySubscription(userId: number): Promise<UserSubscription | null> {
      return await prisma.userSubscription.findFirst({
         where: { userId, status: "ACTIVE" },
         include: { plan: { include: { features: { include: { feature: true } } } } },
         orderBy: { createdAt: "desc" },
      });
   }

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return await prisma.userFeature.findUnique({
         where: { userId }
      });
   }


   async subscribe(userId: number, planId: number): Promise<UserSubscription> {
      const plan = await prisma.subscriptionPlan.findUnique({
         where: { id: planId },
         include: { features: { include: { feature: true } } }
      });

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found");
      }

      if (!plan.isActive) {
         throw new ApiError(400, "This subscription plan is no longer active");
      }

      // Deactivate any existing active subscriptions for this user
      await prisma.userSubscription.updateMany({
         where: { userId, status: "ACTIVE" },
         data: { status: "EXPIRED" },
      });

      // Calculate end date based on durationDays
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + plan.durationDays);

      const userSubscription = await prisma.userSubscription.create({
         data: {
            userId,
            planId,
            status: "ACTIVE",
            startDate,
            endDate,
         },
         include: {
            plan: { include: { features: { include: { feature: true } } } },
         },
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
         const key = pf.feature.key;
         const valStr = pf.limit;
         
         if (key === 'audio_call') newLimits.canAudioCall = valStr === 'true';
         if (key === 'video_call') newLimits.canVideoCall = valStr === 'true';
         if (key === 'send_message') newLimits.canSendMessage = valStr === 'true';
         if (key === 'profile_blur') newLimits.isProfileBlurEnabled = valStr === 'true';
         
         if (key === 'max_interests') newLimits.maxInterests = parseInt(valStr) || 0;
         if (key === 'max_video_call_minutes') newLimits.maxVideoCallMinutes = parseInt(valStr) || 0;
         if (key === 'max_audio_call_minutes') newLimits.maxAudioCallMinutes = parseInt(valStr) || 0;
         if (key === 'max_messages') newLimits.maxMessages = parseInt(valStr) || 0;
      }

      const existingUserFeature = await prisma.userFeature.findUnique({ where: { userId } });

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

      await prisma.userFeature.upsert({
         where: { userId },
         update: {
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
         },
         create: {
            userId,
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
         }
      });

      return userSubscription;
   }
}
