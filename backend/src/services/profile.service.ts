import { ProfileRepository } from "@/repositories/profile.repository";
import { ApiError } from "@/utils/ApiError";

export class ProfileService {
   private profileRepository: ProfileRepository;

   constructor() {
      this.profileRepository = new ProfileRepository();
   }

   async getProfileStructure(userId: number) {
      const sections = await this.profileRepository.getProfileStructure();
      const userAnswers = await this.profileRepository.getUserAnswers(userId);

      // Map answers to questions for easier frontend consumption
      // Or just return both and let frontend handle merging.
      // The API design response 1 is just structure. Response 4 is answers.
      // Let's stick to returning structure only for /questions API as designed.
      return sections;
   }

   async getSections(isPrimary?: boolean) {
      return await this.profileRepository.getSections(isPrimary);
   }

   async getQuestionsBySectionOrder(sectionOrder: number, userId: number) {
      return await this.profileRepository.getQuestionsBySectionByOrder(sectionOrder, userId);
   }

   async getUserAnswers(userId: number) {
      return await this.profileRepository.getUserAnswers(userId);
   }

   async saveAnswer(userId: number, questionId: number, answer: any) {
      // Validate question exists and answer format if needed
      // For now, straight to DB

      // Logic for scoring can be added here
      let score = 0;
      if (answer.value && typeof answer.value === "number") {
         score = answer.value; // Simple pass-through for rating
      }

      return await this.profileRepository.saveAnswer(userId, questionId, answer, score);
   }

   async completeProfile(userId: number) {
      // 1. Check if all required PRIMARY questions are answered
      const requiredCount = await this.profileRepository.getRequiredPrimaryQuestionsCount();
      const answeredCount = await this.profileRepository.getUserPrimaryAnsweredCount(userId);

      if (answeredCount < requiredCount) {
         throw new ApiError(400, "Please answer all mandatory primary questions before completing the profile.");
      }

      // 2. Mark profile as completed (User is done with mandatory part)
      await this.profileRepository.setProfileCompleted(userId);

      return {
         isProfileCompleted: true,
         nextAction: "logout", // Frontend should handle logout
      };
   }
}
