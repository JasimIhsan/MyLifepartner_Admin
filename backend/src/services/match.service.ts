import { notificationService } from "../composer/composer";
import { NotificationType } from "../constants/notificationTypes";
import { CandidateProfile, IMatchRepository, MatchProfileData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";
import { IImageAccessRequestService } from "../interfaces/services/image-access-request.service.interface";
import { IMatchService, InteractionState, MatchRecommendationItem, ProfileDetail, SwipeAction, SwipeInput } from "../interfaces/services/match.service.interface";
import { IPrivacyImageMapperService } from "../interfaces/services/privacy-image-mapper.service.interface";
import { IS3Service } from "../interfaces/services/s3.service.interface";
import { IUserFeatureService } from "../interfaces/services/user.feature.service.interface";
import { ApiError } from "../utils/ApiError";
import logger from "../utils/logger";

type CompatibilityScore = {
   totalScore: number;
   highlights: string[];
};

type WeightedScore = {
   score: number;
   comparableWeight: number;
};

type ScoredCandidate = {
   candidate: CandidateProfile;
   compatibility: CompatibilityScore;
};

type UserMatchContext = {
   viewerUserId: number;
   viewerPrivacyEnabled: boolean;
   approvedAccesses: Set<number>;
   preference: UserPreferenceData | null;
   viewerProfile: MatchProfileData | null;
   preferredMaritalStatuses: Set<string>;
   preferredMotherTongues: Set<string>;
   viewerLanguages: Set<string>;
   sentRequestsMap: Map<number, string>;
};

const MINIMUM_MATCH_PERCENTAGE = 10;
const RECOMMENDATION_LIMIT = 20;
const DEFAULT_PROFILE_NAME = "Unknown";
const DEFAULT_NO_DATA_MATCH_PERCENTAGE = 50;

const PREFERENCE_FIELD_WEIGHTS = {
   age: 18,
   maritalStatus: 27,
   motherTongue: 20,
} as const;

const PROFILE_FIELD_WEIGHTS = {
   city: 5,
   state: 2,
   country: 1,
   highestEducation: 7,
   childrenStatus: 6,
   job: 5,
   maritalStatus: 4,
   lookingFor: 2,
   emotionalReadiness: 1.5,
   languages: 1,
   smokingHabit: 0.25,
   drinkingHabit: 0.25,
} as const;

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

      const topCandidates = this.selectTopScoredCandidates(candidates, matchContext);

      return Promise.all(topCandidates.map(({ candidate, compatibility }) => this.mapCandidateToRecommendationItem(candidate, matchContext, compatibility)));
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
      const { totalScore, highlights } = this.calculateCompatibility(candidate, matchContext);

      const hasApprovedAccess = matchContext.approvedAccesses.has(candidate.userId);
      const isRestricted = (matchContext.viewerPrivacyEnabled || candidate.privacyEnabled) && !hasApprovedAccess;

      return {
         id: candidate.id,
         userId: candidate.userId,
         name: candidate.name ?? DEFAULT_PROFILE_NAME,
         age: this.getCandidateAge(candidate),
         gender: candidate.gender,
         maritalStatus: candidate.maritalStatus,
         city: candidate.city,
         state: candidate.state,
         country: candidate.country,
         motherTongue: candidate.motherTongue,
         highestEducation: candidate.highestEducation,
         occupation: candidate.occupation,
         bio: candidate.bio,
         childrenStatus: candidate.childrenStatus,
         drinkingHabit: candidate.drinkingHabit,
         emotionalReadiness: candidate.emotionalReadiness,
         languages: candidate.languages,
         lookingFor: candidate.lookingFor,
         relationshipTimeline: candidate.relationshipTimeline,
         smokingHabit: candidate.smokingHabit,
         matchPercentage: Math.round(totalScore),
         compatibilityHighlights: isRestricted ? [] : highlights,
         images: await this.getPresignedImages(candidate, matchContext),
         interactionState: candidate.interactionState ?? InteractionState.NONE,
         createdAt: candidate.createdAt,
         lastLoginAt: candidate.lastLoginAt,
         isVerified: candidate.isVerified,
         isFoundingMember: candidate.isFoundingMember,
         isPremium: candidate.isPremium,
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
    * Keeps only the best recommendation candidates before image URL work is performed.
    *
    * @param candidates - Candidate profiles.
    * @param matchContext - Current user's match context.
    * @returns Top scored candidates.
    */
   private selectTopScoredCandidates(candidates: CandidateProfile[], matchContext: UserMatchContext): ScoredCandidate[] {
      const heap: ScoredCandidate[] = [];

      for (const candidate of candidates) {
         const compatibility = this.calculateCompatibility(candidate, matchContext);

         if (Math.round(compatibility.totalScore) < MINIMUM_MATCH_PERCENTAGE) {
            continue;
         }

         const scoredCandidate = { candidate, compatibility };

         if (heap.length < RECOMMENDATION_LIMIT) {
            heap.push(scoredCandidate);
            this.siftScoredCandidateUp(heap, heap.length - 1);
            continue;
         }

         if (this.compareScoredCandidates(scoredCandidate, heap[0]) > 0) {
            heap[0] = scoredCandidate;
            this.siftScoredCandidateDown(heap, 0);
         }
      }

      return heap.sort((a, b) => this.compareScoredCandidates(b, a));
   }

   /**
    * Compares two scored candidates by recommendation priority.
    */
   private compareScoredCandidates(a: ScoredCandidate, b: ScoredCandidate): number {
      const scoreDifference = a.compatibility.totalScore - b.compatibility.totalScore;

      if (scoreDifference !== 0) {
         return scoreDifference;
      }

      return b.candidate.id - a.candidate.id;
   }

   private siftScoredCandidateUp(heap: ScoredCandidate[], index: number): void {
      let currentIndex = index;

      while (currentIndex > 0) {
         const parentIndex = Math.floor((currentIndex - 1) / 2);

         if (this.compareScoredCandidates(heap[currentIndex], heap[parentIndex]) >= 0) {
            break;
         }

         [heap[currentIndex], heap[parentIndex]] = [heap[parentIndex], heap[currentIndex]];
         currentIndex = parentIndex;
      }
   }

   private siftScoredCandidateDown(heap: ScoredCandidate[], index: number): void {
      let currentIndex = index;

      while (true) {
         const leftIndex = currentIndex * 2 + 1;
         const rightIndex = leftIndex + 1;
         let smallestIndex = currentIndex;

         if (leftIndex < heap.length && this.compareScoredCandidates(heap[leftIndex], heap[smallestIndex]) < 0) {
            smallestIndex = leftIndex;
         }

         if (rightIndex < heap.length && this.compareScoredCandidates(heap[rightIndex], heap[smallestIndex]) < 0) {
            smallestIndex = rightIndex;
         }

         if (smallestIndex === currentIndex) {
            break;
         }

         [heap[currentIndex], heap[smallestIndex]] = [heap[smallestIndex], heap[currentIndex]];
         currentIndex = smallestIndex;
      }
   }

   /**
    * Maps candidate profile to recommendation item.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns Match recommendation item.
    */
   private async mapCandidateToRecommendationItem(candidate: CandidateProfile, matchContext: UserMatchContext, compatibility?: CompatibilityScore): Promise<MatchRecommendationItem> {
      const { totalScore, highlights } = compatibility ?? this.calculateCompatibility(candidate, matchContext);

      const hasApprovedAccess = matchContext.approvedAccesses.has(candidate.userId);
      const isRestricted = (matchContext.viewerPrivacyEnabled || candidate.privacyEnabled) && !hasApprovedAccess;

      const name = isRestricted ? (candidate.name ? candidate.name.split(" ")[0] : DEFAULT_PROFILE_NAME) : (candidate.name ?? DEFAULT_PROFILE_NAME);

      return {
         id: candidate.id,
         userId: candidate.userId,
         name,
         age: this.getCandidateAge(candidate),
         city: candidate.city,
         state: candidate.state,
         country: candidate.country,
         isVerified: candidate.isVerified,
         isFoundingMember: candidate.isFoundingMember,
         isPremium: candidate.isPremium,
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
      const [preference, viewerProfile, viewerPrivacyEnabled, approvedAccessesList, sentRequestsList] = await Promise.all([
         this.matchRepository.getUserPreference(userId),
         this.matchRepository.getUserMatchProfile(userId),
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
         viewerProfile,
         preferredMaritalStatuses: this.toNormalizedSet(preference?.maritalStatus ?? []),
         preferredMotherTongues: this.toNormalizedSet(preference?.motherTongue ?? []),
         viewerLanguages: this.toNormalizedSet(viewerProfile?.languages ?? []),
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
         imageId: image.imageId,
         imageUrl: image.presignedImageUrl ?? "",
         presignedImageUrl: image.presignedImageUrl ?? "",
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
    * @param matchContext - Current user's match context.
    * @returns Compatibility score.
    */
   private calculateCompatibility(candidate: CandidateProfile, matchContext: UserMatchContext): CompatibilityScore {
      const preferenceScore = this.calculatePreferenceScore(candidate, matchContext);
      const profileScore = this.calculateProfileScore(candidate, matchContext);
      const totalComparableWeight = preferenceScore.comparableWeight + profileScore.comparableWeight;
      const totalScore = totalComparableWeight === 0 ? DEFAULT_NO_DATA_MATCH_PERCENTAGE : Math.min(preferenceScore.score + profileScore.score, 100);

      return {
         totalScore,
         highlights: this.buildCompatibilityHighlights(candidate, matchContext),
      };
   }

   /**
    * Calculates preference score.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns Preference score.
    */
   private calculatePreferenceScore(candidate: CandidateProfile, matchContext: UserMatchContext): WeightedScore {
      const score = this.createWeightedScore();
      const preference = matchContext.preference;

      if (!preference) {
         return score;
      }

      this.addWeightedMatch(score, PREFERENCE_FIELD_WEIGHTS.age, preference.ageFrom !== null && preference.ageTo !== null, this.isAgeMatched(candidate, preference));

      this.addWeightedMatch(score, PREFERENCE_FIELD_WEIGHTS.maritalStatus, matchContext.preferredMaritalStatuses.size > 0, this.isPreferredMaritalStatusMatched(candidate, matchContext));

      this.addWeightedMatch(score, PREFERENCE_FIELD_WEIGHTS.motherTongue, matchContext.preferredMotherTongues.size > 0, this.isMotherTongueMatched(candidate, matchContext));

      return score;
   }

   /**
    * Calculates profile similarity score.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns Profile similarity score.
    */
   private calculateProfileScore(candidate: CandidateProfile, matchContext: UserMatchContext): WeightedScore {
      const score = this.createWeightedScore();
      const viewerProfile = matchContext.viewerProfile;

      if (!viewerProfile) {
         return score;
      }

      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.city, viewerProfile.city, candidate.city);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.state, viewerProfile.state, candidate.state);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.country, viewerProfile.country, candidate.country);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.highestEducation, viewerProfile.highestEducation, candidate.highestEducation);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.childrenStatus, viewerProfile.childrenStatus, candidate.childrenStatus);
      this.addWeightedMatch(score, PROFILE_FIELD_WEIGHTS.job, this.hasJobData(viewerProfile), this.isJobMatched(candidate, viewerProfile));
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.maritalStatus, viewerProfile.maritalStatus, candidate.maritalStatus);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.lookingFor, viewerProfile.lookingFor, candidate.lookingFor);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.emotionalReadiness, viewerProfile.emotionalReadiness, candidate.emotionalReadiness);
      this.addWeightedMatch(score, PROFILE_FIELD_WEIGHTS.languages, matchContext.viewerLanguages.size > 0, this.hasSharedLanguage(candidate, matchContext.viewerLanguages));
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.smokingHabit, viewerProfile.smokingHabit, candidate.smokingHabit);
      this.addTextMatch(score, PROFILE_FIELD_WEIGHTS.drinkingHabit, viewerProfile.drinkingHabit, candidate.drinkingHabit);

      return score;
   }

   /**
    * Builds compatibility highlights.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns Compatibility highlights.
    */
   private buildCompatibilityHighlights(candidate: CandidateProfile, matchContext: UserMatchContext): string[] {
      const highlights: string[] = [];
      const viewerProfile = matchContext.viewerProfile;

      if (matchContext.preference && this.isAgeMatched(candidate, matchContext.preference)) {
         highlights.push("Matches age preference");
      }

      if (this.isPreferredMaritalStatusMatched(candidate, matchContext)) {
         highlights.push("Preferred marital status");
      }

      if (this.isMotherTongueMatched(candidate, matchContext)) {
         highlights.push("Preferred mother tongue");
      }

      if (this.isSameText(viewerProfile?.city, candidate.city)) {
         highlights.push("Same city");
      }

      if (this.isSameText(viewerProfile?.highestEducation, candidate.highestEducation)) {
         highlights.push("Similar education");
      }

      if (this.isSameText(viewerProfile?.childrenStatus, candidate.childrenStatus)) {
         highlights.push("Similar children status");
      }

      if (viewerProfile && this.isJobMatched(candidate, viewerProfile)) {
         highlights.push("Same profession");
      }

      if (this.hasSharedLanguage(candidate, matchContext.viewerLanguages)) {
         highlights.push("Shared language");
      }

      if (this.isSameText(viewerProfile?.lookingFor, candidate.lookingFor)) {
         highlights.push("Similar relationship goal");
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
    * Checks preferred marital status match.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns True if marital status matches preferences.
    */
   private isPreferredMaritalStatusMatched(candidate: CandidateProfile, matchContext: UserMatchContext): boolean {
      const maritalStatus = this.normalizeText(candidate.maritalStatus);

      return Boolean(maritalStatus && matchContext.preferredMaritalStatuses.has(maritalStatus));
   }

   /**
    * Checks mother tongue match.
    *
    * @param candidate - Candidate profile.
    * @param matchContext - Current user's match context.
    * @returns True if mother tongue matches.
    */
   private isMotherTongueMatched(candidate: CandidateProfile, matchContext: UserMatchContext): boolean {
      const motherTongue = this.normalizeText(candidate.motherTongue);

      return Boolean(motherTongue && matchContext.preferredMotherTongues.has(motherTongue));
   }

   /**
    * Creates a mutable weighted score accumulator.
    */
   private createWeightedScore(): WeightedScore {
      return {
         score: 0,
         comparableWeight: 0,
      };
   }

   /**
    * Adds a weighted score when a field can be compared.
    */
   private addWeightedMatch(score: WeightedScore, weight: number, canCompare: boolean, isMatched: boolean): void {
      if (!canCompare) {
         return;
      }

      score.comparableWeight += weight;

      if (isMatched) {
         score.score += weight;
      }
   }

   /**
    * Adds a weighted exact text match.
    */
   private addTextMatch(score: WeightedScore, weight: number, viewerValue: string | null | undefined, candidateValue: string | null | undefined): void {
      this.addWeightedMatch(score, weight, this.hasText(viewerValue), this.isSameText(viewerValue, candidateValue));
   }

   private hasJobData(profile: MatchProfileData): boolean {
      return profile.jobId !== null || this.hasText(profile.occupation);
   }

   private isJobMatched(candidate: CandidateProfile, viewerProfile: MatchProfileData): boolean {
      if (viewerProfile.jobId !== null && candidate.jobId !== null) {
         return viewerProfile.jobId === candidate.jobId;
      }

      return this.isSameText(viewerProfile.occupation, candidate.occupation);
   }

   private hasSharedLanguage(candidate: CandidateProfile, viewerLanguages: Set<string>): boolean {
      if (viewerLanguages.size === 0 || candidate.languages.length === 0) {
         return false;
      }

      return candidate.languages.some((language) => {
         const normalizedLanguage = this.normalizeText(language);

         return Boolean(normalizedLanguage && viewerLanguages.has(normalizedLanguage));
      });
   }

   private toNormalizedSet(values: string[]): Set<string> {
      return new Set(values.map((value) => this.normalizeText(value)).filter((value): value is string => Boolean(value)));
   }

   private isSameText(firstValue: string | null | undefined, secondValue: string | null | undefined): boolean {
      const first = this.normalizeText(firstValue);
      const second = this.normalizeText(secondValue);

      return Boolean(first && second && first === second);
   }

   private hasText(value: string | null | undefined): boolean {
      return Boolean(this.normalizeText(value));
   }

   private normalizeText(value: string | null | undefined): string | null {
      const normalizedValue = value?.trim().toLowerCase();

      return normalizedValue ? normalizedValue : null;
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
