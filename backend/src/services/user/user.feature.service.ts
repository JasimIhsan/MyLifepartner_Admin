import { UserFeature } from "@prisma/client";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";

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
}
