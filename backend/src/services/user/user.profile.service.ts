import { ImageUploadStatusDto, UserImageDto, toImageUploadStatusDto, toUserImageDto } from "@/dtos/image.dto";

import { ProfileQuestionDto, ProfileSectionDto, ProfileStatusDto, UserAnswerDto, toProfileQuestionDto, toProfileSectionDto, toProfileStatusDto, toUserAnswerDto } from "@/dtos/profile.dto";
import { IProfileRepository } from "@/interfaces/repositories/profile.repository.interface";
import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { ApiError } from "@/utils/ApiError";
import { PartnerPreference, Profile, ProfileStatus } from "@prisma/client";
import { UpdateProfileDto, CreatePartnerPreferenceDto } from "@/dtos/profile.input.dto";

export class ProfileService implements IProfileService {
   constructor(private profileRepository: IProfileRepository) {}

   /**
    * Retrieves the structure of the profile, including sections and questions
    * @param userId - The ID of the user
    * @returns Array of profile sections mapped to DTOs
    */
   async getProfileStructure(userId: number): Promise<ProfileSectionDto[]> {
      const sections = await this.profileRepository.getProfileStructure();
      const userAnswers = await this.profileRepository.getUserAnswers(userId);

      // Map answers to questions for easier frontend consumption
      // Or just return both and let frontend handle merging.
      // The API design response 1 is just structure. Response 4 is answers.
      // Let's stick to returning structure only for /questions API as designed.
      return sections.map((s) => toProfileSectionDto(s));
   }

   /**
    * Retrieves all profile sections
    * @param isPrimary - Optional flag to filter primary sections
    * @returns Array of profile sections mapped to DTOs
    */
   async getSections(isPrimary?: boolean): Promise<ProfileSectionDto[]> {
      const sections = await this.profileRepository.getSections(isPrimary);
      return sections.map((s) => toProfileSectionDto(s));
   }

   /**
    * Retrieves questions for a specific section order
    * @param sectionOrder - The order number of the section
    * @param userId - The ID of the user
    * @returns Array of profile questions mapped to DTOs
    */
   async getQuestionsBySectionOrder(sectionOrder: number, userId: number): Promise<ProfileQuestionDto[]> {
      const questions = await this.profileRepository.getQuestionsBySectionByOrder(sectionOrder, userId);
      return questions.map((q) => toProfileQuestionDto(q));
   }

   /**
    * Retrieves all answers submitted by a user
    * @param userId - The ID of the user
    * @returns Array of user answers mapped to DTOs
    */
   async getUserAnswers(userId: number): Promise<UserAnswerDto[]> {
      const answers = await this.profileRepository.getUserAnswers(userId);
      return answers.map((a) => toUserAnswerDto(a));
   }

   /**
    * Saves an answer to a specific profile question
    * @param userId - The ID of the user
    * @param questionId - The ID of the question
    * @param answer - The answer content
    * @returns The saved answer mapped to a DTO
    */
   async saveAnswer(userId: number, questionId: number, answer: unknown): Promise<UserAnswerDto> {
      // Validate question exists and answer format if needed
      // For now, straight to DB

      // Logic for scoring can be added here
      let score = 0;
      if (answer && typeof answer === "object" && !Array.isArray(answer) && "value" in answer) {
         const answerObj = answer as { value?: unknown };
         if (typeof answerObj.value === "number") {
            score = answerObj.value; // Simple pass-through for rating
         }
      }

      const savedAnswer = await this.profileRepository.saveAnswer(userId, questionId, answer, score);
      return toUserAnswerDto(savedAnswer);
   }

   /**
    * Marks the user's profile as completed if all mandatory questions are answered
    * @param userId - The ID of the user
    * @returns The updated profile status DTO
    * @throws ApiError if mandatory primary questions are not fully answered
    */
   async completeProfile(userId: number): Promise<ProfileStatusDto> {
      const primaryRequiredCount = await this.profileRepository.getRequiredQuestionsCount(true);
      const primaryAnsweredCount = await this.profileRepository.getUserAnsweredCount(userId, true);

      if (primaryAnsweredCount < primaryRequiredCount) {
         throw new ApiError(400, "Please answer all mandatory primary questions before completing the profile.");
      }

      const totalRequiredCount = await this.profileRepository.getRequiredQuestionsCount();
      const totalAnsweredCount = await this.profileRepository.getUserAnsweredCount(userId);

      const isFullyCompleted = totalAnsweredCount >= totalRequiredCount;
      const newStatus = isFullyCompleted ? ProfileStatus.COMPLETED : ProfileStatus.ONBOARDING_COMPLETED;

      await this.profileRepository.updateProfileStatus(userId, newStatus);

      return toProfileStatusDto(newStatus, "logout");
   }

   /**
    * Retrieves the user's profile completion status
    * @param userId - The ID of the user
    * @returns An object indicating if the profile is complete and the next pending section order
    */
   async getProfileCompletionStatus(userId: number) {
      const totalRequiredCount = await this.profileRepository.getRequiredQuestionsCount();
      const totalAnsweredCount = await this.profileRepository.getUserAnsweredCount(userId);

      const isCompleted = totalAnsweredCount >= totalRequiredCount;
      let nextPendingSectionOrder = 1;

      if (!isCompleted) {
         const sections = await this.profileRepository.getSections();
         for (const section of sections) {
            const sectionQuestions = await this.profileRepository.getQuestionsBySectionByOrder(section.orderNo, userId);
            const pendingQuestion = sectionQuestions.find((q) => q.isRequired && q.answers.length === 0);
            if (pendingQuestion) {
               nextPendingSectionOrder = section.orderNo;
               break;
            }
         }
      }

      return {
         isCompleted,
         nextPendingSectionOrder,
      };
   }

   /**
    * Updates basic profile details of a user
    * @param userId - The ID of the user
    * @param data - The DTO containing the basic details to update
    * @returns The updated Profile object
    */
   async updateBasicProfile(userId: number, data: UpdateProfileDto): Promise<Profile> {
      return this.profileRepository.updateBasicProfile(userId, data);
   }

   /**
    * Updates the partner preferences for a user
    * @param userId - The ID of the user
    * @param data - The DTO containing the partner preferences
    * @returns The updated PartnerPreference object
    */
   async updatePartnerPreference(userId: number, data: CreatePartnerPreferenceDto): Promise<PartnerPreference> {
      return this.profileRepository.updatePartnerPreference(userId, data);
   }

   async getUserImages(userId: number): Promise<UserImageDto[]> {
      const images = await this.profileRepository.getUserImages(userId);
      return images.map((img) => toUserImageDto(img));
   }

   async uploadUserImage(userId: number, imageUrl: string): Promise<UserImageDto> {
      const currentCount = await this.profileRepository.getUserImagesCount(userId);
      if (currentCount >= 4) {
         throw new ApiError(400, "Maximum of 4 images allowed");
      }

      // If it's the first image, make it primary automatically
      const isPrimary = currentCount === 0;

      const image = await this.profileRepository.saveUserImage(userId, imageUrl, isPrimary);
      return toUserImageDto(image);
   }

   async deleteUserImage(userId: number, imageId: number): Promise<{ success: boolean }> {
      const image = await this.profileRepository.getUserImageById(imageId);
      if (!image) {
         throw new ApiError(404, "Image not found");
      }
      if (image.profile?.userId !== userId) {
         throw new ApiError(403, "Forbidden to delete this image");
      }

      await this.profileRepository.deleteUserImage(imageId);
      return { success: true };
   }

   async setPrimaryImage(userId: number, imageId: number): Promise<UserImageDto> {
      const image = await this.profileRepository.getUserImageById(imageId);
      if (!image) {
         throw new ApiError(404, "Image not found");
      }
      if (image.profile?.userId !== userId) {
         throw new ApiError(403, "Forbidden to modify this image");
      }

      await this.profileRepository.unsetPrimaryImages(userId);
      const updatedImage = await this.profileRepository.setImageAsPrimary(imageId);

      return toUserImageDto(updatedImage);
   }

   async completeImageUpload(userId: number): Promise<ImageUploadStatusDto> {
      const images = await this.profileRepository.getUserImages(userId);
      if (images.length !== 4) {
         throw new ApiError(400, "Exactly 4 images are required to proceed");
      }
      const hasPrimary = images.some((img) => img.isPrimary);
      if (!hasPrimary) {
         throw new ApiError(400, "One image must be selected as primary");
      }

      await this.profileRepository.completeImageUpload(userId);
      return toImageUploadStatusDto(true, true);
   }

   async uploadSelfie(userId: number, frontUrl: string, leftUrl: string, rightUrl: string, latitude?: number, longitude?: number) {
      return await this.profileRepository.saveSelfie(userId, frontUrl, leftUrl, rightUrl, latitude, longitude);
   }
}
