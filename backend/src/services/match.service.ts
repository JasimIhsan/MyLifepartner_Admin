import { SwipeAction } from "@prisma/client";
import { CandidateProfile, IMatchRepository, UserAnswerData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";
import { IMatchService, InteractionState, MatchRecommendationItem, ProfileDetail, SwipeInput } from "../interfaces/services/match.service.interface";
import { IS3Service } from "../interfaces/services/s3.service.interface";
import { IUserFeatureService } from "../interfaces/services/user.feature.service.interface";
import { ApiError } from "../utils/ApiError";

type CompatibilityScore = {
   totalScore: number;
   highlights: string[];
};

export class MatchService implements IMatchService {
   constructor(
      private readonly matchRepository: IMatchRepository,
      private readonly s3Service: IS3Service,
      private readonly userFeatureService: IUserFeatureService
   ) {}

   async getRecommendations(userId: number): Promise<MatchRecommendationItem[]> {
      // 1. Fetch preferences & answers of current user
      const [userPref, userAnswers, swipedProfiles] = await Promise.all([this.matchRepository.getUserPreference(userId), this.matchRepository.getUserAnswers(userId), this.matchRepository.getSwipedProfileIds(userId)]);

      // Profiles already swiped LEFT or RIGHT should not appear; UP (skip) can appear again
      const excludedIds = swipedProfiles.filter((s) => s.action === SwipeAction.LEFT || s.action === SwipeAction.RIGHT).map((s) => s.targetProfileId);

      // 2. Fetch eligible candidate profiles
      const candidates = await this.matchRepository.getCandidateProfiles(userId, excludedIds);

      console.log(`👉 candidates : `, candidates);

      // 3. Score each candidate
      const scored: MatchRecommendationItem[] = [];
      for (const candidate of candidates) {
         const { totalScore, highlights } = this.calculateCompatibility(candidate, userPref, userAnswers);

         console.log(`👉 totalScore : `, totalScore);
         console.log(`👉 highlights : `, highlights);

         // 4. Filter by minimum 70%
         if (totalScore >= 10) {
            const age = candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : 0;

            const presignedImages = await Promise.all(
               candidate.images.map(async (img) => ({
                  ...img,
                  imageUrl: await this.s3Service.getPresignedUrl(img.imageUrl),
               }))
            );

            scored.push({
               id: candidate.id,
               name: candidate.name ?? "Unknown",
               age,
               heightCm: candidate.heightCm,
               city: candidate.city,
               religion: candidate.religion,
               isVerified: candidate.isVerified,
               occupation: candidate.occupation,
               matchPercentage: Math.round(totalScore),
               compatibilityHighlights: highlights,
               images: presignedImages,
               interactionState: candidate.interactionState ?? InteractionState.NONE,
            });
         }
      }

      console.log(`👉 scored : `, scored);

      // 5. Sort descending and limit to 20
      scored.sort((a, b) => b.matchPercentage - a.matchPercentage);
      return scored.slice(0, 20);
   }

   async swipeProfile(input: SwipeInput): Promise<void> {
      const isAllowed = await this.userFeatureService.checkSwipeAccess(input.userId, input.action);
      console.log(`isAllowed : `, isAllowed);
      if (!isAllowed) {
         throw new ApiError(402, "You have reached your interest limit. Upgrade your plan to send more interests!");
      }

      await this.matchRepository.recordSwipe(input.userId, input.targetProfileId, input.action);

      // Consume the swipe (decrement limit if applicable)
      await this.userFeatureService.consumeSwipe(input.userId, input.action);
   }

   async getProfileDetail(userId: number, profileId: number): Promise<ProfileDetail | null> {
      const candidate = await this.matchRepository.getProfileById(userId, profileId);
      if (!candidate) return null;

      const [userPref, userAnswers] = await Promise.all([this.matchRepository.getUserPreference(userId), this.matchRepository.getUserAnswers(userId)]);

      const { totalScore, highlights } = this.calculateCompatibility(candidate, userPref, userAnswers);
      const age = candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : 0;

      const presignedImages = await Promise.all(
         candidate.images.map(async (img) => ({
            ...img,
            imageUrl: await this.s3Service.getPresignedUrl(img.imageUrl),
         }))
      );

      return {
         id: candidate.id,
         name: candidate.name ?? "Unknown",
         age,
         gender: candidate.gender,
         heightCm: candidate.heightCm,
         maritalStatus: candidate.maritalStatus,
         city: candidate.city,
         state: candidate.state,
         country: candidate.country,
         religion: candidate.religion,
         motherTongue: candidate.motherTongue,
         highestEducation: candidate.highestEducation,
         occupation: candidate.occupation,
         annualIncome: candidate.annualIncome,
         bio: candidate.bio,
         matchPercentage: Math.round(totalScore),
         compatibilityHighlights: highlights,
         images: presignedImages,
         interactionState: candidate.interactionState ?? InteractionState.NONE,
      };
   }

   async getSentInterests(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getSentInterests(userId);
      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   async getReceivedInterests(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getReceivedInterests(userId);
      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   async getMutualMatches(userId: number): Promise<MatchRecommendationItem[]> {
      const profiles = await this.matchRepository.getMutualMatches(userId);
      return this.enrichCandidatesToRecommendations(userId, profiles);
   }

   private async enrichCandidatesToRecommendations(userId: number, candidates: CandidateProfile[]): Promise<MatchRecommendationItem[]> {
      const [userPref, userAnswers] = await Promise.all([this.matchRepository.getUserPreference(userId), this.matchRepository.getUserAnswers(userId)]);

      const result: MatchRecommendationItem[] = [];

      for (const candidate of candidates) {
         const { totalScore, highlights } = this.calculateCompatibility(candidate, userPref, userAnswers);
         const age = candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : 0;

         const presignedImages = await Promise.all(
            candidate.images.map(async (img) => ({
               ...img,
               imageUrl: await this.s3Service.getPresignedUrl(img.imageUrl),
            }))
         );

         result.push({
            id: candidate.id,
            name: candidate.name ?? "Unknown",
            age,
            heightCm: candidate.heightCm,
            city: candidate.city,
            isVerified: candidate.isVerified,
            religion: candidate.religion,
            occupation: candidate.occupation,
            matchPercentage: Math.round(totalScore),
            compatibilityHighlights: highlights,
            images: presignedImages,
            interactionState: candidate.interactionState ?? InteractionState.NONE,
         });
      }

      return result;
   }

   // ─── Private scoring helpers ──────────────────────────────────────────────

   private calculateCompatibility(candidate: CandidateProfile, pref: UserPreferenceData | null, userAnswers: UserAnswerData[]): CompatibilityScore {
      let totalScore = 0;
      const highlights: string[] = [];

      if (!pref) {
         // No preferences set – return a moderate base score
         return { totalScore: 70, highlights: [] };
      }

      // Age (10 pts)
      const age = candidate.dateOfBirth ? this.calculateAge(candidate.dateOfBirth) : null;
      if (age !== null && pref.ageFrom !== null && pref.ageTo !== null) {
         if (age >= pref.ageFrom && age <= pref.ageTo) {
            totalScore += 10;
         }
      }

      // Height (10 pts)
      if (candidate.heightCm !== null && pref.heightFrom !== null && pref.heightTo !== null && candidate.heightCm >= pref.heightFrom && candidate.heightCm <= pref.heightTo) {
         totalScore += 10;
      }

      // Religion (10 pts)
      if (candidate.religion && pref.religion.length > 0) {
         if (pref.religion.includes(candidate.religion)) {
            totalScore += 10;
            highlights.push("✔ Same Religion");
         }
      }

      // Mother tongue (10 pts)
      if (candidate.motherTongue && pref.motherTongue.length > 0) {
         if (pref.motherTongue.includes(candidate.motherTongue)) {
            totalScore += 10;
            highlights.push("✔ Same Mother Tongue");
         }
      }

      // Education (10 pts)
      if (candidate.highestEducation && pref.highestEducation.length > 0) {
         if (pref.highestEducation.includes(candidate.highestEducation)) {
            totalScore += 10;
            highlights.push("✔ Similar Education");
         }
      }

      // Occupation (10 pts)
      if (candidate.occupation && pref.occupation.length > 0) {
         if (pref.occupation.includes(candidate.occupation)) {
            totalScore += 10;
         }
      }

      // Income (10 pts)
      if (candidate.annualIncome !== null && pref.annualIncomeFrom !== null && pref.annualIncomeTo !== null && candidate.annualIncome >= pref.annualIncomeFrom && candidate.annualIncome <= pref.annualIncomeTo) {
         totalScore += 10;
      }

      // Location (10 pts)
      // We give 10 points based on presence of city data for now
      if (candidate.city) {
         totalScore += 10;
      }

      // Max score without personality based on the 8 criteria above is 80 (8 * 10)
      // We normalize it to 100 for the percentage
      totalScore = Math.round((totalScore / 80) * 100);

      // Personality / Answer compatibility (10 pts)
      // const personalityScore = this.calculatePersonalityScore(candidate.answers, userAnswers);
      // totalScore += personalityScore;

      return { totalScore: Math.min(totalScore, 100), highlights: highlights.slice(0, 3) };
   }

   private calculatePersonalityScore(candidateAnswers: UserAnswerData[], userAnswers: UserAnswerData[]): number {
      if (userAnswers.length === 0 || candidateAnswers.length === 0) return 0;

      const userAnswerMap = new Map(userAnswers.map((a) => [a.questionId, a]));
      let matches = 0;
      let compared = 0;

      for (const cAnswer of candidateAnswers) {
         const uAnswer = userAnswerMap.get(cAnswer.questionId);
         if (!uAnswer) continue;
         compared++;

         // Compare answer values (JSON)
         const cVal = JSON.stringify(cAnswer.answer);
         const uVal = JSON.stringify(uAnswer.answer);
         if (cVal === uVal) matches++;
         // Score-based similarity
         else if (cAnswer.score !== null && uAnswer.score !== null) {
            const diff = Math.abs((cAnswer.score ?? 0) - (uAnswer.score ?? 0));
            if (diff <= 1) matches += 0.5;
         }
      }

      if (compared === 0) return 0;
      return Math.round((matches / compared) * 10);
   }

   private calculateAge(dateOfBirth: Date): number {
      const today = new Date();
      let age = today.getFullYear() - dateOfBirth.getFullYear();
      const m = today.getMonth() - dateOfBirth.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < dateOfBirth.getDate())) age--;
      return age;
   }
}
