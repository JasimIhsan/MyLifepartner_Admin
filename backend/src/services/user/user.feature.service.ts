import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { ApiError } from "@/utils/ApiError";
import { SwipeAction, UserFeature } from "@prisma/client";
import { hasFeature, hasReachedLimit, UserFeatureMaxKey, UserFeatureUsageKey } from "@/utils/feature.utils";

export class UserFeatureService implements IUserFeatureService {
   constructor(private userFeatureRepository: IUserFeatureRepository) {}

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   async createDefaultFeatures(userId: number): Promise<UserFeature> {
      return this.userFeatureRepository.create({
         user: { connect: { id: userId } },
      });
   }

   async updateInterests(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new ApiError(404, "User features not found");

      return this.userFeatureRepository.update(userId, {
         interests: Math.max(0, features.interests + amount),
      });
   }

   async updateMessages(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new ApiError(404, "User features not found");

      return this.userFeatureRepository.update(userId, {
         messages: Math.max(0, features.messages + amount),
      });
   }

   async updateVideoCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new ApiError(404, "User features not found");

      return this.userFeatureRepository.update(userId, {
         videoCallMinutes: Math.max(0, features.videoCallMinutes + amount),
      });
   }

   async updateAudioCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new ApiError(404, "User features not found");

      return this.userFeatureRepository.update(userId, {
         audioCallMinutes: Math.max(0, features.audioCallMinutes + amount),
      });
   }

   async checkSwipeAccess(userId: number, action: SwipeAction): Promise<boolean> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      console.log("features:", features);

      if (!features || !hasFeature(features, UserFeatureMaxKey.MAX_INTERESTS)) return false;

      if (action === SwipeAction.RIGHT || action === SwipeAction.LEFT) {
         return !hasReachedLimit(features, UserFeatureMaxKey.MAX_INTERESTS, UserFeatureUsageKey.INTERESTS);
      }

      return false;
   }

   async consumeSwipe(userId: number, action: SwipeAction): Promise<void> {
      if (action !== SwipeAction.RIGHT && action !== SwipeAction.LEFT) return;

      const features = await this.userFeatureRepository.findByUserId(userId);

      if (!features || !hasFeature(features, UserFeatureMaxKey.MAX_INTERESTS)) {
         throw new ApiError(404, "User features not found");
      }

      if (hasReachedLimit(features, UserFeatureMaxKey.MAX_INTERESTS, UserFeatureUsageKey.INTERESTS)) {
         throw new ApiError(402, "You have reached your interest limit. Upgrade your plan to send more interests!");
      }

      await this.updateInterests(userId, 1);
   }

   async checkMessageAccess(userId: number): Promise<boolean> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features || !hasFeature(features, UserFeatureMaxKey.MAX_MESSAGES)) return false;
      return !hasReachedLimit(features, UserFeatureMaxKey.MAX_MESSAGES, UserFeatureUsageKey.MESSAGES);
   }

   async consumeMessage(userId: number): Promise<void> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      console.log("👉 features:", features);
      if (!features || !hasFeature(features, UserFeatureMaxKey.MAX_MESSAGES)) {
         throw new ApiError(402, "Message feature not available in your plan.");
      }
      if (hasReachedLimit(features, UserFeatureMaxKey.MAX_MESSAGES, UserFeatureUsageKey.MESSAGES)) {
         throw new ApiError(402, "You have reached your message limit. Upgrade your plan to send more messages.");
      }
      await this.updateMessages(userId, 1);
   }

   async consumeCallDuration(userId: number, type: "audio" | "video", durationSeconds: number): Promise<void> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) return;
      if (type === "audio") {
         await this.updateAudioCallMinutes(userId, durationSeconds);
      } else {
         await this.updateVideoCallMinutes(userId, durationSeconds);
      }
   }
}
