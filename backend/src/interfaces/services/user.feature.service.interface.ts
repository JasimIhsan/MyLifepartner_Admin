import { UserFeature } from "@prisma/client";

export interface IUserFeatureService {
   getUserFeatures(userId: number): Promise<UserFeature | null>;
   createDefaultFeatures(userId: number): Promise<UserFeature>;
   updateRemainingInterests(userId: number, amount: number): Promise<UserFeature>;
   updateRemainingMessages(userId: number, amount: number): Promise<UserFeature>;
   updateRemainingVideoCallMinutes(userId: number, amount: number): Promise<UserFeature>;
   updateRemainingAudioCallMinutes(userId: number, amount: number): Promise<UserFeature>;
}
