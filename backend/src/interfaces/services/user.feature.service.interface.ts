import { UserFeature, SwipeAction } from "@prisma/client";

export interface IUserFeatureService {
   getUserFeatures(userId: number): Promise<UserFeature | null>;
   createDefaultFeatures(userId: number): Promise<UserFeature>;
   updateInterests(userId: number, amount: number): Promise<UserFeature>;
   updateMessages(userId: number, amount: number): Promise<UserFeature>;
   updateVideoCallMinutes(userId: number, amount: number): Promise<UserFeature>;
   updateAudioCallMinutes(userId: number, amount: number): Promise<UserFeature>;
   checkSwipeAccess(userId: number, action: SwipeAction): Promise<boolean>;
   consumeSwipe(userId: number, action: SwipeAction): Promise<void>;
   checkMessageAccess(userId: number): Promise<boolean>;
   consumeMessage(userId: number): Promise<void>;
   consumeCallDuration(userId: number, type: "audio" | "video", durationSeconds: number): Promise<void>;
   checkCallAccess(userId: number, type: "audio" | "video", consumeSeconds?: number, targetUserId?: number): Promise<void>;
}
