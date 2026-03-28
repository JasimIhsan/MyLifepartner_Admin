import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { ApiError } from "@/utils/ApiError";
import { SwipeAction, UserFeature } from "@prisma/client";

export class UserFeatureService implements IUserFeatureService {
   constructor(private userFeatureRepository: IUserFeatureRepository) {}

   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   async createDefaultFeatures(userId: number): Promise<UserFeature> {
      return this.userFeatureRepository.create({
         user: { connect: { id: userId } },
         // default columns will be handled by DB or explicit here
      });
   }

   async updateRemainingInterests(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new Error("Features not found");
      return this.userFeatureRepository.update(userId, {
         remainingInterests: features.remainingInterests + amount,
      });
   }

   async updateRemainingMessages(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new Error("Features not found");
      return this.userFeatureRepository.update(userId, {
         remainingMessages: features.remainingMessages + amount,
      });
   }

   async updateRemainingVideoCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new Error("Features not found");
      return this.userFeatureRepository.update(userId, {
         remainingVideoCallMinutes: features.remainingVideoCallMinutes + amount,
      });
   }

   async updateRemainingAudioCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) throw new Error("Features not found");
      return this.userFeatureRepository.update(userId, {
         remainingAudioCallMinutes: features.remainingAudioCallMinutes + amount,
      });
   }

   async checkSwipeAccess(userId: number, action: SwipeAction): Promise<boolean> {
      const features = await this.userFeatureRepository.findByUserId(userId);
      if (!features) return false;

      if ((action === SwipeAction.RIGHT || action === SwipeAction.LEFT) && features.remainingInterests > 0) {
         return true;
      }

      return false;
   }

   async consumeSwipe(userId: number, action: SwipeAction): Promise<void> {
      if (action === SwipeAction.RIGHT || action === SwipeAction.LEFT) {
         const features = await this.userFeatureRepository.findByUserId(userId);
         if (features && features.remainingInterests > 0) {
            await this.updateRemainingInterests(userId, -1);
         } else {
            throw new ApiError(403, "You have reached your interest limit. Upgrade your plan to send more interests!");
         }
      }
   }
}
