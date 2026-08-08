import { CandidateProfile, IMatchRepository, UserAnswerData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";
import { IImageAccessRequestService } from "../interfaces/services/image-access-request.service.interface";
import { IMatchService, InteractionState, MatchRecommendationItem, ProfileDetail, SwipeAction, SwipeInput } from "../interfaces/services/match.service.interface";
import { IPrivacyImageMapperService } from "../interfaces/services/privacy-image-mapper.service.interface";
import { IS3Service } from "../interfaces/services/s3.service.interface";
import { IUserFeatureService } from "../interfaces/services/user.feature.service.interface";
import { notificationService } from "../composer/composer";
import { NotificationType } from "../constants/notificationTypes";
import { ApiError } from "../utils/ApiError";
import logger from "../utils/logger";

type CompatibilityScore = {
   totalScore: number;
   highlights: string[];
};

type UserMatchContext = {
   viewerUserId: number;
   viewerPrivacyEnabled: boolean;
   approvedAccesses: Set<number>;
   preference: UserPreferenceData | null;
   answers: UserAnswerData[];
   sentRequestsMap: Map<number, string>;
};

const MINIMUM_MATCH_PERCENTAGE = 10;
const RECOMMENDATION_LIMIT = 20;
const DEFAULT_PROFILE_NAME = "Unknown";

export class MatchService implements IMatchService {
   constructor(
      private readonly matchRepository: IMatchRepository,
      private readonly s3Service: IS3Service,
      private readonly userFeatureService: IUserFeatureService,
      private readonly privacyImageMapperService: IPrivacyImageMapperService,
      private readonly imageAccessRequestService: IImageAccessRequestService
   ) {}

   /**
    * Gets recommended profiles for a user.
    *
    * @param userId - User ID.
    * @returns Recommended match profiles.
    */
   async getRecommendations(userId: number): Promise<MatchRecommendationItem[]> {
      const [matchContext, swipedProfiles] = await Promise.all([this.getUserMatchContext(userId), this.matchRepository.getSwipedProfileIds(userId)]);

      const excludedProfileIds = swipedProfiles.filter((swipe) => swipe.action === SwipeAction.LEFT || swipe.action === SwipeAction.RIGHT).map((swipe) => swipe.targetProfileId);

      const candidates = await this.matchRepository.getCandidateProfiles(userId, excludedProfileIds);

      const recommendations = await this.buildRecommendationItems(candidates, matchContext);

      return recommendations
         .filter((recommendation) => recommendation.matchPercentage >= MINIMUM_MATCH_PERCENTAGE)
         .sort((a, b) => b.matchPercentage - a.matchPercentage)
         .slice(0, RECOMMENDATION_LIMIT);
   }

   /**
    * Records a profile swipe.
    *
    * @param input - Swipe input data.
    * @returns Nothing.
    */
   async swipeProfile(input: SwipeInput): Promise<void> {
      const { userId, targetProfileId, action } = input;

      if (userId === targetProfileId) {
         throw new ApiError(400, "You cannot swipe your own profile");
      }

      const isAllowed = await this.userFeatureService.checkSwipeAccess(input.userId, input.action);

      if (!isAllowed) {
         throw new ApiError(402, "You have reached your interest limit. Upgrade your plan to send more interests!");
      }

      await this.matchRepository.recordSwipe(input.userId, input.targetProfileId, input.action);

      await this.userFeatureService.consumeSwipe(input.userId, input.action);

      if (action === SwipeAction.RIGHT) {
         this.handleSwipeNotification(userId, targetProfileId).catch((error) => {
            logger.error(`Failed to dispatch swipe notification for user ${userId}:`, error);
         });
      }
   }

   /**
    * Handles sending push notifications for swipe right (interest sent / interest accepted).
    */
   private async handleSwipeNotification(userId: number, targetProfileId: number): Promise<void> {
      const context = await this.matchRepository.getSwipeNotificationContext(userId, targetProfileId);
      if (!context) {
         return;
      }

      const { swiperUserId, swiperName, targetUserId, targetName, isMutualMatch } = context;

      if (isMutualMatch) {
         // Notify target user (who swiped right earlier) that a match is created
         await notificationService.sendToUser({
            userId: targetUserId,
            type: NotificationType.NEW_MATCH,
            title: "It's a Match! 🎉",
            body: `You and ${swiperName} liked each other! Start chatting now.`,
            data: {
               type: NotificationType.NEW_MATCH,
               profileId: String(swiperUserId),
            },
         });

         // Notify swiper user that their interest was accepted / mutual match formed
         await notificationService.sendToUser({
            userId: swiperUserId,
            type: NotificationType.INTEREST_ACCEPTED,
            title: "Interest Accepted! 🎉",
            body: `${targetName} accepted your interest! You can now start chatting.`,
            data: {
               type: NotificationType.INTEREST_ACCEPTED,
               profileId: String(targetProfileId),
            },
         });
      } else {
         // Notify target user that someone showed interest in their profile
         await notificationService.sendToUser({
            userId: targetUserId,
            type: NotificationType.NEW_LIKE,
            title: "New Interest Received!",
            body: `${swiperName} showed interest in your profile!`,
            data: {
               type: NotificationType.NEW_LIKE,
               profileId: String(swiperUserId),
            },
         });
      }
   }

   /**
    * Gets profile details.
    *
    * @param userId - Current user ID.
    * @param profileId - Profile ID.
    * @returns Profile details, or null if not found.
    */
   async getProfileDetail(userId: number, profileId: number): Promise<ProfileDetail | null> {
      const candidate = await this.matchRepository.getProfileById(userId, profileId);

      if (!candidate) {
         return null;
      }

      const matchContext = await this.getUserMatchContext(userId, [candidate.userId]);
      const { totalScore, highlights } = this.calculateCompatibility(candidate, matchContext.preference, matchContext.answers);

      const hasApprovedAccess = matchContext.approvedAccesses.has(candidate.userId);
      const isRestricted = (matchContext.viewerPrivacyEnabled || candidate.privacyEnabled) && !hasApprovedAccess;

      const name = isRestricted ? (candidate.name ? candidate.name.split(" ")[0] : DEFAULT_PROFILE_NAME) : (candidate.name ?? DEFAULT_PROFILE_NAME);

      return {
         id: candidate.id,
         userId: candidate.userId,
         name,
         age: this.getCandidateAge(candidate),
         gender: isRestricted ? null : candidate.gender,
         maritalStatus: isRestricted ? null : candidate.maritalStatus,
         city: candidate.city,
         state: isRestricted ? null : candidate.state,
         country: candidate.country,
         motherTongue: isRestricted ? null : candidate.motherTongue,
         highestEducation: isRestricted ? null : candidate.highestEducation,
         occupation: isRestricted ? null : candidate.occupation,
         bio: candidate.bio,
         childrenStatus: isRestricted ? null : candidate.childrenStatus,
         drinkingHabit: isRestricted ? null : candidate.drinkingHabit,
         emotionalReadiness: isRestricted ? null : candidate.emotionalReadiness,
         languages: isRestricted ? [] : candidate.languages,
         lookingFor: isRestricted ? null : candidate.lookingFor,
         relationshipTimeline: isRestricted ? null : candidate.relationshipTimeline,
         smokingHabit: isRestricted ? null : candidate.smokingHabit,
         matchPercentage: Math.round(totalScore),
         compatibilityHighlights: isRestricted ? [] : highlights,
         images: await this.getPresignedImages(candidate, matchContext),
         interactionState: candidate.interactionState ?? InteractionState.NONE,
         createdAt: candidate.createdAt,
         lastLoginAt: candidate.lastLoginAt,
         isVerified: candidate.isVerified,
         viewerPrivacyEnabled: matchContext.viewerPrivacyEnabled,
         targetPrivacyEnabled: candidate.privacyEnabled,
         imageAccessRequestStatus: matchContext.sentRequestsMap.get(candidate.userId) ?? null,
      };
   }

   /**
    * Gets sent interest profiles.
    *
    * @param userId - User ID.
    * @returns Sent interest profiles.
    */
   async getSentInterests(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getSentInterests(userId);

      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   /**
    * Gets received interest profiles.
    *
    * @param userId - User ID.
    * @returns Received interest profiles.
    */
   async getReceivedInterests(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getReceivedInterests(userId);

      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   /**
    * Gets mutual match profiles.
    *
    * @param userId - User ID.
    * @returns Mutual match profiles.
    */
   async getMutualMatches(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getMutualMatches(userId);

      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   /**
    * Converts candidate profiles to recommendation items.
    *
    * @param userId - User ID.
    * @param candidates - Candidate profiles.
    * @returns Match recommendation items.
    */
   private async enrichCandidatesToRecommendations(userId: number, candidates: CandidateProfile[]): Promise<MatchRecommendationItem[]> {
      const matchContext = await this.getUserMatchContext(
         userId,
         candidates.map((c) => c.userId)
      );

      return this.buildRecommendationItems(candidates, matchContext);
   }

   /**
    * Builds recommendation items.
    *
    * @param candidates - Candidate profiles.
    * @param matchContext - Current user's match context.
    * @returns Match recommendation items.
    */
   private async buildRecommendationItems(candidates: CandidateProfile[], matchContext: UserMatchContext): Promise<MatchRecommendationItem[]> {
      return Promise.all(candidates.map((candidate) => this.mapCandidateToRecommendationItem(candidate, matchContext)));
   }

   /**
    * Maps candidate profile to recommendation item.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns Match recommendation item.
    */
   private async mapCandidateToRecommendationItem(candidate: CandidateProfile, matchContext: UserMatchContext): Promise<MatchRecommendationItem> {
      const { totalScore, highlights } = this.calculateCompatibility(candidate, matchContext.preference, matchContext.answers);

      const hasApprovedAccess = matchContext.approvedAccesses.has(candidate.userId);
      const isRestricted = (matchContext.viewerPrivacyEnabled || candidate.privacyEnabled) && !hasApprovedAccess;

      const name = isRestricted ? (candidate.name ? candidate.name.split(" ")[0] : DEFAULT_PROFILE_NAME) : (candidate.name ?? DEFAULT_PROFILE_NAME);

      return {
         id: candidate.id,
         userId: candidate.userId,
         name,
         age: this.getCandidateAge(candidate),
         city: candidate.city,
         country: candidate.country,
         isVerified: candidate.isVerified,
         occupation: isRestricted ? null : candidate.occupation,
         maritalStatus: isRestricted ? null : candidate.maritalStatus,
         matchPercentage: Math.round(totalScore),
         compatibilityHighlights: isRestricted ? [] : highlights,
         images: await this.getPresignedImages(candidate, matchContext),
         interactionState: candidate.interactionState ?? InteractionState.NONE,
         createdAt: candidate.createdAt,
         lastLoginAt: candidate.lastLoginAt,
         viewerPrivacyEnabled: matchContext.viewerPrivacyEnabled,
         targetPrivacyEnabled: candidate.privacyEnabled,
         imageAccessRequestStatus: matchContext.sentRequestsMap.get(candidate.userId) ?? null,
      };
   }

   /**
    * Gets current user's match context.
    *
    * @param userId - User ID.
    * @returns User match context.
    */
   private async getUserMatchContext(userId: number, candidateUserIds: number[] = []): Promise<UserMatchContext> {
      const [preference, answers, viewerPrivacyEnabled, approvedAccessesList, sentRequestsList] = await Promise.all([
         this.matchRepository.getUserPreference(userId),
         this.matchRepository.getUserAnswers(userId),
         this.matchRepository.getViewerPrivacyStatus(userId),
         this.imageAccessRequestService.getApprovedAccessesForViewer(userId, candidateUserIds),
         this.imageAccessRequestService.getSentRequests(userId),
      ]);

      const approvedAccesses = new Set(approvedAccessesList.map((a) => a.ownerUserId));
      const sentRequestsMap = new Map<number, string>();
      for (const req of sentRequestsList) {
         sentRequestsMap.set(req.ownerUserId, req.status);
      }

      return {
         viewerUserId: userId,
         viewerPrivacyEnabled,
         approvedAccesses,
         preference,
         answers,
         sentRequestsMap,
      };
   }

   /**
    * Gets presigned image URLs.
    *
    * @param candidate - Candidate profile.
    * @returns Images with presigned URLs.
    */
   private async getPresignedImages(candidate: CandidateProfile, matchContext: UserMatchContext) {
      const mappedImages = await this.privacyImageMapperService.mapImages({
         viewerUserId: matchContext.viewerUserId,
         viewerPrivacyEnabled: matchContext.viewerPrivacyEnabled,
         targetUserId: candidate.userId,
         targetPrivacyEnabled: candidate.privacyEnabled,
         targetBlurredImageUrl: candidate.blurredImageUrl,
         targetImages: candidate.images.map((img) => ({
            id: img.id,
            imageUrl: img.imageUrl,
            isPrimary: img.isPrimary,
         })),
         hasApprovedAccess: matchContext.approvedAccesses.has(candidate.userId),
      });

      return mappedImages.map((image) => ({
         id: image.id,
         imageUrl: image.imageUrl ?? "",
         isPrimary: image.isPrimary,
         isBlurred: image.isBlurred,
      }));
   }

   /**
    * Gets candidate age.
    *
    * @param candidate - Candidate profile.
    * @returns Candidate age.
    */
   private getCandidateAge(candidate: CandidateProfile): number {
      return candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : 0;
   }

   /**
    * Calculates compatibility score.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @param userAnswers - User answer data.
    * @returns Compatibility score.
    */
   private calculateCompatibility(candidate: CandidateProfile, preference: UserPreferenceData | null, userAnswers: UserAnswerData[]): CompatibilityScore {
      if (!preference) {
         return {
            totalScore: 70,
            highlights: [],
         };
      }

      const preferenceScore = this.calculatePreferenceScore(candidate, preference);
      const personalityScore = this.calculatePersonalityScore(candidate.answers, userAnswers);

      const totalScore = Math.min(preferenceScore + personalityScore, 100);

      return {
         totalScore,
         highlights: this.buildCompatibilityHighlights(candidate, preference),
      };
   }

   /**
    * Calculates preference score.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @returns Preference score.
    */
   private calculatePreferenceScore(candidate: CandidateProfile, preference: UserPreferenceData): number {
      let score = 0;

      if (this.isAgeMatched(candidate, preference)) {
         score += 10;
      }

      if (this.isHeightMatched(candidate, preference)) {
         score += 10;
      }

      if (this.isMotherTongueMatched(candidate, preference)) {
         score += 10;
      }

      if (candidate.city) {
         score += 10;
      }

      return Math.round((score / 40) * 90);
   }

   /**
    * Builds compatibility highlights.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @returns Compatibility highlights.
    */
   private buildCompatibilityHighlights(candidate: CandidateProfile, preference: UserPreferenceData): string[] {
      const highlights: string[] = [];

      if (this.isMotherTongueMatched(candidate, preference)) {
         highlights.push("✔ Same Mother Tongue");
      }

      return highlights.slice(0, 3);
   }

   /**
    * Checks age match.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @returns True if age matches.
    */
   private isAgeMatched(candidate: CandidateProfile, preference: UserPreferenceData): boolean {
      const age = candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : null;

      return age !== null && preference.ageFrom !== null && preference.ageTo !== null && age >= preference.ageFrom && age <= preference.ageTo;
   }

   /**
    * Checks height match.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @returns True if height matches.
    */
   private isHeightMatched(candidate: CandidateProfile, preference: UserPreferenceData): boolean {
      return true;
   }

   /**
    * Checks mother tongue match.
    *
    * @param candidate - Candidate profile.
    * @param preference - User preference data.
    * @returns True if mother tongue matches.
    */
   private isMotherTongueMatched(candidate: CandidateProfile, preference: UserPreferenceData): boolean {
      return Boolean(candidate.motherTongue && preference.motherTongue.length > 0 && preference.motherTongue.includes(candidate.motherTongue));
   }

   /**
    * Calculates personality score.
    *
    * @param candidateAnswers - Candidate answers.
    * @param userAnswers - Current user answers.
    * @returns Personality score.
    */
   private calculatePersonalityScore(candidateAnswers: UserAnswerData[], userAnswers: UserAnswerData[]): number {
      if (userAnswers.length === 0 || candidateAnswers.length === 0) {
         return 0;
      }

      const userAnswerMap = new Map(userAnswers.map((answer) => [answer.questionId, answer]));

      let matches = 0;
      let compared = 0;

      for (const candidateAnswer of candidateAnswers) {
         const userAnswer = userAnswerMap.get(candidateAnswer.questionId);

         if (!userAnswer) {
            continue;
         }

         compared += 1;

         if (this.areAnswersSame(candidateAnswer.answer, userAnswer.answer)) {
            matches += 1;
            continue;
         }

         if (this.areScoresClose(candidateAnswer.score, userAnswer.score)) {
            matches += 0.5;
         }
      }

      if (compared === 0) {
         return 0;
      }

      return Math.round((matches / compared) * 10);
   }

   /**
    * Checks if answers are same.
    *
    * @param candidateAnswer - Candidate answer.
    * @param userAnswer - Current user answer.
    * @returns True if answers are same.
    */
   private areAnswersSame(candidateAnswer: unknown, userAnswer: unknown): boolean {
      return JSON.stringify(candidateAnswer) === JSON.stringify(userAnswer);
   }

   /**
    * Checks if scores are close.
    *
    * @param candidateScore - Candidate score.
    * @param userScore - Current user score.
    * @returns True if scores are close.
    */
   private areScoresClose(candidateScore: number | null, userScore: number | null): boolean {
      if (candidateScore === null || userScore === null) {
         return false;
      }

      return Math.abs(candidateScore - userScore) <= 1;
   }

   /**
    * Calculates age from date of birth.
    *
    * @param dateOfBirth - Date of birth.
    * @returns Age.
    */
   private calculateAge(dateOfBirth: Date): number {
      const today = new Date();
      let age = today.getFullYear() - dateOfBirth.getFullYear();

      const monthDifference = today.getMonth() - dateOfBirth.getMonth();
      const hasBirthdayPassed = monthDifference > 0 || (monthDifference === 0 && today.getDate() >= dateOfBirth.getDate());

      if (!hasBirthdayPassed) {
         age -= 1;
      }

      return age;
   }

   /**
    * Cancels a swipe interest request and refunds 1 interest count.
    */
   async cancelSwipeInterest(userId: number, targetProfileId: number): Promise<void> {
      const deleted = await this.matchRepository.deleteSwipe(userId, targetProfileId);
      if (deleted) {
         await this.userFeatureService.updateInterests(userId, -1);
      }
   }
}
