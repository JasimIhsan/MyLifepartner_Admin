import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { SwipeAction } from "@/interfaces/services/match.service.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { ApiError } from "@/utils/ApiError";
import { hasFeature, hasReachedLimit, UserFeatureMaxKey, UserFeatureUsageKey } from "@/utils/feature.utils";
import { UserFeature } from "@/interfaces/services/user.feature.service.interface";

type CallType = "audio" | "video";

const PAYMENT_REQUIRED_STATUS = 402;
const NOT_FOUND_STATUS = 404;
const MIN_FEATURE_USAGE = 0;

export class UserFeatureService implements IUserFeatureService {
   constructor(private readonly userFeatureRepository: IUserFeatureRepository) {}

   /**
    * Gets user features.
    *
    * @param userId - User ID.
    * @returns User features, or null if not found.
    */
   async getUserFeatures(userId: number): Promise<UserFeature | null> {
      return this.userFeatureRepository.findByUserId(userId);
   }

   /**
    * Creates default user features.
    *
    * @param userId - User ID.
    * @returns Created user features.
    */
   async createDefaultFeatures(userId: number): Promise<UserFeature> {
      return this.userFeatureRepository.create({
         user: {
            connect: {
               id: userId,
            },
         },
      });
   }

   /**
    * Updates interest usage.
    *
    * @param userId - User ID.
    * @param amount - Amount to add or subtract.
    * @returns Updated user features.
    */
   async updateInterests(userId: number, amount: number): Promise<UserFeature> {
      return this.updateFeatureUsage(userId, "interests", amount);
   }

   /**
    * Updates message usage.
    *
    * @param userId - User ID.
    * @param amount - Amount to add or subtract.
    * @returns Updated user features.
    */
   async updateMessages(userId: number, amount: number): Promise<UserFeature> {
      return this.updateFeatureUsage(userId, "messages", amount);
   }

   /**
    * Updates video call minutes usage.
    *
    * @param userId - User ID.
    * @param amount - Amount to add or subtract.
    * @returns Updated user features.
    */
   async updateVideoCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      return this.updateFeatureUsage(userId, "videoCallMinutes", amount);
   }

   /**
    * Updates audio call minutes usage.
    *
    * @param userId - User ID.
    * @param amount - Amount to add or subtract.
    * @returns Updated user features.
    */
   async updateAudioCallMinutes(userId: number, amount: number): Promise<UserFeature> {
      return this.updateFeatureUsage(userId, "audioCallMinutes", amount);
   }

   /**
    * Checks swipe access.
    *
    * @param userId - User ID.
    * @param action - Swipe action.
    * @returns True if swipe is allowed.
    */
   async checkSwipeAccess(userId: number, action: SwipeAction): Promise<boolean> {
      if (!this.isLimitedSwipeAction(action)) {
         return false;
      }

      const features = await this.userFeatureRepository.findByUserId(userId);

      if (!features) {
         return false;
      }

      return this.hasAvailableLimit(features, UserFeatureMaxKey.MAX_INTERESTS, UserFeatureUsageKey.INTERESTS);
   }

   /**
    * Consumes swipe usage.
    *
    * @param userId - User ID.
    * @param action - Swipe action.
    * @returns Nothing.
    */
   async consumeSwipe(userId: number, action: SwipeAction): Promise<void> {
      if (!this.isLimitedSwipeAction(action)) {
         return;
      }

      const features = await this.getRequiredFeatures(userId);

      this.ensureFeatureAvailable(features, UserFeatureMaxKey.MAX_INTERESTS, "Interest feature not available in your plan.");

      this.ensureFeatureLimitNotReached(features, UserFeatureMaxKey.MAX_INTERESTS, UserFeatureUsageKey.INTERESTS, "You have reached your interest limit. Upgrade your plan to send more interests!");

      await this.updateInterests(userId, 1);
   }

   /**
    * Checks message access.
    *
    * @param userId - User ID.
    * @returns True if message is allowed.
    */
   async checkMessageAccess(userId: number): Promise<boolean> {
      const features = await this.userFeatureRepository.findByUserId(userId);

      if (!features) {
         return false;
      }

      return this.hasAvailableLimit(features, UserFeatureMaxKey.MAX_MESSAGES, UserFeatureUsageKey.MESSAGES);
   }

   /**
    * Consumes message usage.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   async consumeMessage(userId: number): Promise<void> {
      const features = await this.getRequiredFeatures(userId);

      this.ensureFeatureAvailable(features, UserFeatureMaxKey.MAX_MESSAGES, "Message feature not available in your plan.");

      this.ensureFeatureLimitNotReached(features, UserFeatureMaxKey.MAX_MESSAGES, UserFeatureUsageKey.MESSAGES, "You have reached your message limit. Upgrade your plan to send more messages.");

      await this.updateMessages(userId, 1);
   }

   /**
    * Consumes call duration usage.
    *
    * @param userId - User ID.
    * @param type - Call type.
    * @param durationSeconds - Call duration in seconds.
    * @returns Nothing.
    */
   async consumeCallDuration(userId: number, type: CallType, durationSeconds: number): Promise<void> {
      const features = await this.userFeatureRepository.findByUserId(userId);

      if (!features || durationSeconds <= 0) {
         return;
      }

      if (type === "audio") {
         await this.updateAudioCallMinutes(userId, durationSeconds);
         return;
      }

      await this.updateVideoCallMinutes(userId, durationSeconds);
   }

   /**
    * Checks call access.
    *
    * @param userId - Caller user ID.
    * @param type - Call type.
    * @param consumeSeconds - Optional duration to consume.
    * @param targetUserId - Optional recipient user ID.
    * @returns Nothing.
    */
   async checkCallAccess(userId: number, type: CallType, consumeSeconds?: number, targetUserId?: number): Promise<void> {
      if (targetUserId !== undefined && targetUserId === userId) {
         throw new ApiError(400, "You cannot call yourself");
      }

      if (!targetUserId && consumeSeconds && consumeSeconds > 0) {
         await this.consumeCallDuration(userId, type, consumeSeconds);
      }

      const checkUserId = targetUserId ?? userId;
      const features = await this.userFeatureRepository.findByUserId(checkUserId);

      if (!features) {
         throw new ApiError(PAYMENT_REQUIRED_STATUS, targetUserId ? "Recipient's plan does not support calls at this time." : "Call feature not available in your plan.");
      }

      if (type === "video") {
         this.ensureVideoCallAccess(features, Boolean(targetUserId));
         return;
      }

      this.ensureAudioCallAccess(features, Boolean(targetUserId));
   }

   /**
    * Updates a user feature usage field.
    *
    * @param userId - User ID.
    * @param key - User feature usage key.
    * @param amount - Amount to add or subtract.
    * @returns Updated user features.
    */
   private async updateFeatureUsage(userId: number, key: "interests" | "messages" | "videoCallMinutes" | "audioCallMinutes", amount: number): Promise<UserFeature> {
      const features = await this.getRequiredFeatures(userId);

      return this.userFeatureRepository.update(userId, {
         [key]: Math.max(MIN_FEATURE_USAGE, features[key] + amount),
      });
   }

   /**
    * Gets required user features.
    *
    * @param userId - User ID.
    * @returns User features.
    */
   private async getRequiredFeatures(userId: number): Promise<UserFeature> {
      const features = await this.userFeatureRepository.findByUserId(userId);

      if (!features) {
         throw new ApiError(NOT_FOUND_STATUS, "User features not found");
      }

      return features;
   }

   /**
    * Checks if a feature has available limit.
    *
    * @param features - User features.
    * @param maxKey - Feature max key.
    * @param usageKey - Feature usage key.
    * @returns True if feature is available and limit is not reached.
    */
   private hasAvailableLimit(features: UserFeature, maxKey: UserFeatureMaxKey, usageKey: UserFeatureUsageKey): boolean {
      return hasFeature(features, maxKey) && !hasReachedLimit(features, maxKey, usageKey);
   }

   /**
    * Ensures a feature is available.
    *
    * @param features - User features.
    * @param maxKey - Feature max key.
    * @param message - Error message.
    * @returns Nothing.
    */
   private ensureFeatureAvailable(features: UserFeature, maxKey: UserFeatureMaxKey, message: string): void {
      if (!hasFeature(features, maxKey)) {
         throw new ApiError(PAYMENT_REQUIRED_STATUS, message);
      }
   }

   /**
    * Ensures a feature limit is not reached.
    *
    * @param features - User features.
    * @param maxKey - Feature max key.
    * @param usageKey - Feature usage key.
    * @param message - Error message.
    * @returns Nothing.
    */
   private ensureFeatureLimitNotReached(features: UserFeature, maxKey: UserFeatureMaxKey, usageKey: UserFeatureUsageKey, message: string): void {
      if (hasReachedLimit(features, maxKey, usageKey)) {
         throw new ApiError(PAYMENT_REQUIRED_STATUS, message);
      }
   }

   /**
    * Checks if swipe action consumes limit.
    *
    * @param action - Swipe action.
    * @returns True if action consumes limit.
    */
   private isLimitedSwipeAction(action: SwipeAction): boolean {
      return action === SwipeAction.RIGHT || action === SwipeAction.LEFT;
   }

   /**
    * Ensures video call access.
    *
    * @param features - User features.
    * @param isRecipientCheck - Whether checking recipient access.
    * @returns Nothing.
    */
   private ensureVideoCallAccess(features: UserFeature, isRecipientCheck: boolean): void {
      this.ensureFeatureAvailable(features, UserFeatureMaxKey.MAX_VIDEO_CALL_MINUTES, isRecipientCheck ? "Recipient's plan does not support video calls." : "Video call not available in your plan.");

      this.ensureFeatureLimitNotReached(features, UserFeatureMaxKey.MAX_VIDEO_CALL_MINUTES, UserFeatureUsageKey.VIDEO_CALL_MINUTES, isRecipientCheck ? "Recipient is temporarily unavailable for video calls." : "Video call limit exhausted.");
   }

   /**
    * Ensures audio call access.
    *
    * @param features - User features.
    * @param isRecipientCheck - Whether checking recipient access.
    * @returns Nothing.
    */
   private ensureAudioCallAccess(features: UserFeature, isRecipientCheck: boolean): void {
      this.ensureFeatureAvailable(features, UserFeatureMaxKey.MAX_AUDIO_CALL_MINUTES, isRecipientCheck ? "Recipient's plan does not support audio calls." : "Audio call not available in your plan.");

      this.ensureFeatureLimitNotReached(features, UserFeatureMaxKey.MAX_AUDIO_CALL_MINUTES, UserFeatureUsageKey.AUDIO_CALL_MINUTES, isRecipientCheck ? "Recipient is temporarily unavailable for audio calls." : "Audio call limit exhausted.");
   }
}
