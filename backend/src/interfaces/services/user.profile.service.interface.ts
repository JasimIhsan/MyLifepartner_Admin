import { ImageUploadStatusDto, UserImageDto } from "@/dtos/image.dto";
import { ProfileQuestionDto, ProfileSectionDto, ProfileStatusDto, UserAnswerDto } from "@/dtos/profile.dto";
import { PartnerPreference, Prisma, Profile } from "@prisma/client";

export interface IProfileService {
   getProfileStructure(userId: number): Promise<ProfileSectionDto[]>;
   getSections(isPrimary?: boolean): Promise<ProfileSectionDto[]>;
   getQuestionsBySectionOrder(sectionOrder: number, userId: number): Promise<ProfileQuestionDto[]>;
   getUserAnswers(userId: number): Promise<UserAnswerDto[]>;
   saveAnswer(userId: number, questionId: number, answer: Prisma.InputJsonValue): Promise<UserAnswerDto>;
   completeProfile(userId: number): Promise<ProfileStatusDto>;
   getProfileCompletionStatus(userId: number): Promise<{ isCompleted: boolean; nextPendingSectionOrder: number }>;
   updateBasicProfile(userId: number, data: Prisma.ProfileUpdateInput): Promise<Profile>;
   updatePartnerPreference(userId: number, data: Omit<Prisma.PartnerPreferenceCreateInput, "user">): Promise<PartnerPreference>;
   getUserImages(userId: number): Promise<UserImageDto[]>;
   uploadUserImage(userId: number, imageUrl: string): Promise<UserImageDto>;
   deleteUserImage(userId: number, imageId: number): Promise<{ success: boolean }>;
   setPrimaryImage(userId: number, imageId: number): Promise<UserImageDto>;
   completeImageUpload(userId: number): Promise<ImageUploadStatusDto>;
   uploadSelfie(userId: number, imageUrl: string): Promise<{ user: import("@prisma/client").Profile; oldSelfieUrl: string | null }>;
}
