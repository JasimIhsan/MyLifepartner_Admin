import { ImageUploadStatusDto, toImageUploadStatusDto, toUserImageDto, UserImageDto } from "@/dtos/image.dto";
import { ProfileQuestionDto, ProfileSectionDto, ProfileStatusDto, toProfileQuestionDto, toProfileSectionDto, toProfileStatusDto, toUserAnswerDto, UserAnswerDto } from "@/dtos/profile.dto";
import { CreatePartnerPreferenceDto, UpdateProfileDto } from "@/dtos/profile.input.dto";
import { IProfileRepository } from "@/interfaces/repositories/profile.repository.interface";
import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { ApiError } from "@/utils/ApiError";
import { PartnerPreference, Profile, ProfileStatus } from "@/interfaces/services/user.profile.service.interface";

type ProfileCompletionStatus = {
   isCompleted: boolean;
   nextPendingSectionOrder: number;
};

type DeleteImageResponse = {
   success: boolean;
};

const MAX_USER_IMAGES = 4;
const DEFAULT_NEXT_PENDING_SECTION_ORDER = 1;

export class ProfileService implements IProfileService {
   constructor(private readonly profileRepository: IProfileRepository) {}

   /**
    * Gets profile structure.
    *
    * @param userId - User ID.
    * @returns Profile sections.
    */
   async getProfileStructure(_userId: number): Promise<ProfileSectionDto[]> {
      const sections = await this.profileRepository.getProfileStructure();

      return sections.map(toProfileSectionDto);
   }

   /**
    * Gets profile sections.
    *
    * @param isPrimary - Optional primary section filter.
    * @returns Profile sections.
    */
   async getSections(isPrimary?: boolean): Promise<ProfileSectionDto[]> {
      const sections = await this.profileRepository.getSections(isPrimary);

      return sections.map(toProfileSectionDto);
   }

   /**
    * Gets questions by section order.
    *
    * @param sectionOrder - Section order number.
    * @param userId - User ID.
    * @returns Profile questions.
    */
   async getQuestionsBySectionOrder(sectionOrder: number, userId: number): Promise<ProfileQuestionDto[]> {
      const questions = await this.profileRepository.getQuestionsBySectionByOrder(sectionOrder, userId);

      return questions.map(toProfileQuestionDto);
   }

   /**
    * Gets user answers.
    *
    * @param userId - User ID.
    * @returns User answers.
    */
   async getUserAnswers(userId: number): Promise<UserAnswerDto[]> {
      const answers = await this.profileRepository.getUserAnswers(userId);

      return answers.map(toUserAnswerDto);
   }

   /**
    * Saves a user answer.
    *
    * @param userId - User ID.
    * @param questionId - Question ID.
    * @param answer - User answer.
    * @returns Saved user answer.
    */
   async saveAnswer(userId: number, questionId: number, answer: unknown): Promise<UserAnswerDto> {
      const score = this.extractAnswerScore(answer);

      const savedAnswer = await this.profileRepository.saveAnswer(userId, questionId, answer, score);

      return toUserAnswerDto(savedAnswer);
   }

   /**
    * Completes user profile.
    *
    * @param userId - User ID.
    * @returns Profile status.
    */
   async completeProfile(userId: number): Promise<ProfileStatusDto> {
      await this.ensurePrimaryQuestionsAnswered(userId);

      const [totalRequiredCount, totalAnsweredCount] = await Promise.all([this.profileRepository.getRequiredQuestionsCount(), this.profileRepository.getUserAnsweredCount(userId)]);

      const isFullyCompleted = totalAnsweredCount >= totalRequiredCount;
      const profileStatus = isFullyCompleted ? ProfileStatus.COMPLETED : ProfileStatus.ONBOARDING_COMPLETED;

      await this.profileRepository.updateProfileStatus(userId, profileStatus);

      return toProfileStatusDto(profileStatus, "logout");
   }

   /**
    * Gets profile completion status.
    *
    * @param userId - User ID.
    * @returns Profile completion status.
    */
   async getProfileCompletionStatus(userId: number): Promise<ProfileCompletionStatus> {
      const [totalRequiredCount, totalAnsweredCount] = await Promise.all([this.profileRepository.getRequiredQuestionsCount(), this.profileRepository.getUserAnsweredCount(userId)]);

      const isCompleted = totalAnsweredCount >= totalRequiredCount;

      if (isCompleted) {
         return {
            isCompleted,
            nextPendingSectionOrder: DEFAULT_NEXT_PENDING_SECTION_ORDER,
         };
      }

      const nextPendingSectionOrder = await this.findNextPendingSectionOrder(userId);

      return {
         isCompleted,
         nextPendingSectionOrder,
      };
   }

   /**
    * Updates basic profile.
    *
    * @param userId - User ID.
    * @param data - Profile update data.
    * @returns Updated profile.
    */
   async updateBasicProfile(userId: number, data: UpdateProfileDto): Promise<Profile> {
      return this.profileRepository.updateBasicProfile(userId, data) as unknown as Profile;
   }

   /**
    * Updates partner preference.
    *
    * @param userId - User ID.
    * @param data - Partner preference data.
    * @returns Updated partner preference.
    */
   async updatePartnerPreference(userId: number, data: CreatePartnerPreferenceDto): Promise<PartnerPreference> {
      return this.profileRepository.updatePartnerPreference(userId, data) as unknown as PartnerPreference;
   }

   /**
    * Gets user images.
    *
    * @param userId - User ID.
    * @returns User images.
    */
   async getUserImages(userId: number): Promise<UserImageDto[]> {
      const images = await this.profileRepository.getUserImages(userId);

      return images.map(toUserImageDto);
   }

   /**
    * Uploads user image.
    *
    * @param userId - User ID.
    * @param imageUrl - Image URL.
    * @returns Uploaded user image.
    */
   async uploadUserImage(userId: number, imageUrl: string): Promise<UserImageDto> {
      const currentCount = await this.profileRepository.getUserImagesCount(userId);

      if (currentCount >= MAX_USER_IMAGES) {
         throw new ApiError(400, "Maximum of 4 images allowed");
      }

      const isPrimary = currentCount === 0;
      const image = await this.profileRepository.saveUserImage(userId, imageUrl, isPrimary);

      return toUserImageDto(image);
   }

   /**
    * Deletes user image.
    *
    * @param userId - User ID.
    * @param imageId - Image ID.
    * @returns Delete status.
    */
   async deleteUserImage(userId: number, imageId: number): Promise<DeleteImageResponse> {
      const image = await this.getOwnedUserImage(userId, imageId);

      await this.profileRepository.deleteUserImage(image.id);

      return {
         success: true,
      };
   }

   /**
    * Sets image as primary.
    *
    * @param userId - User ID.
    * @param imageId - Image ID.
    * @returns Updated user image.
    */
   async setPrimaryImage(userId: number, imageId: number): Promise<UserImageDto> {
      await this.getOwnedUserImage(userId, imageId);

      await this.profileRepository.unsetPrimaryImages(userId);

      const updatedImage = await this.profileRepository.setImageAsPrimary(imageId);

      return toUserImageDto(updatedImage);
   }

   /**
    * Completes image upload.
    *
    * @param userId - User ID.
    * @returns Image upload status.
    */
   async completeImageUpload(userId: number): Promise<ImageUploadStatusDto> {
      const images = await this.profileRepository.getUserImages(userId);

      if (images.length !== MAX_USER_IMAGES) {
         throw new ApiError(400, "Exactly 4 images are required to proceed");
      }

      const hasPrimaryImage = images.some((image) => image.isPrimary);

      if (!hasPrimaryImage) {
         throw new ApiError(400, "One image must be selected as primary");
      }

      await this.profileRepository.completeImageUpload(userId);

      return toImageUploadStatusDto(true, true);
   }

   /**
    * Uploads user selfie.
    *
    * @param userId - User ID.
    * @param frontUrl - Front selfie URL.
    * @param leftUrl - Left selfie URL.
    * @param rightUrl - Right selfie URL.
    * @param latitude - Optional latitude.
    * @param longitude - Optional longitude.
    * @returns Updated selfie data.
    */
   async uploadSelfie(userId: number, frontUrl: string, leftUrl: string, rightUrl: string, latitude?: number, longitude?: number) {
      const result = await this.profileRepository.saveSelfie(userId, frontUrl, leftUrl, rightUrl, latitude, longitude);
      return {
         ...result,
         user: result.user as unknown as Profile,
      };
   }

   /**
    * Ensures primary questions are answered.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   private async ensurePrimaryQuestionsAnswered(userId: number): Promise<void> {
      const [primaryRequiredCount, primaryAnsweredCount] = await Promise.all([this.profileRepository.getRequiredQuestionsCount(true), this.profileRepository.getUserAnsweredCount(userId, true)]);

      if (primaryAnsweredCount < primaryRequiredCount) {
         throw new ApiError(400, "Please answer all mandatory primary questions before completing the profile.");
      }
   }

   /**
    * Finds next pending section order.
    *
    * @param userId - User ID.
    * @returns Next pending section order.
    */
   private async findNextPendingSectionOrder(userId: number): Promise<number> {
      const sections = await this.profileRepository.getSections();

      for (const section of sections) {
         const questions = await this.profileRepository.getQuestionsBySectionByOrder(section.orderNo, userId);

         const hasPendingQuestion = questions.some((question) => question.isRequired && question.answers.length === 0);

         if (hasPendingQuestion) {
            return section.orderNo;
         }
      }

      return DEFAULT_NEXT_PENDING_SECTION_ORDER;
   }

   /**
    * Gets owned user image.
    *
    * @param userId - User ID.
    * @param imageId - Image ID.
    * @returns User image.
    */
   private async getOwnedUserImage(userId: number, imageId: number) {
      const image = await this.profileRepository.getUserImageById(imageId);

      if (!image) {
         throw new ApiError(404, "Image not found");
      }

      if (image.profile?.userId !== userId) {
         throw new ApiError(403, "Forbidden to modify this image");
      }

      return image;
   }

   /**
    * Extracts answer score.
    *
    * @param answer - User answer.
    * @returns Answer score.
    */
   private extractAnswerScore(answer: unknown): number {
      if (!answer || typeof answer !== "object" || Array.isArray(answer)) {
         return 0;
      }

      if (!("value" in answer)) {
         return 0;
      }

      const value = answer.value;

      return typeof value === "number" ? value : 0;
   }
}
