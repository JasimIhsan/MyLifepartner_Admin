import { ImageUploadStatusDto, UserImageDto } from "@/dtos/image.dto";
import { ProfileQuestionDto, ProfileSectionDto, ProfileStatusDto, UserAnswerDto } from "@/dtos/profile.dto";
import { PartnerPreference, Profile } from "@prisma/client";
import { UpdateProfileDto, CreatePartnerPreferenceDto } from "@/dtos/profile.input.dto";

export interface IProfileService {
   getProfileStructure(userId: number): Promise<ProfileSectionDto[]>;
   getSections(isPrimary?: boolean): Promise<ProfileSectionDto[]>;
   getQuestionsBySectionOrder(sectionOrder: number, userId: number): Promise<ProfileQuestionDto[]>;
   getUserAnswers(userId: number): Promise<UserAnswerDto[]>;
   saveAnswer(userId: number, questionId: number, answer: unknown): Promise<UserAnswerDto>;
   completeProfile(userId: number): Promise<ProfileStatusDto>;
   getProfileCompletionStatus(userId: number): Promise<{ isCompleted: boolean; nextPendingSectionOrder: number }>;
   updateBasicProfile(userId: number, data: UpdateProfileDto): Promise<Profile>;
   updatePartnerPreference(userId: number, data: CreatePartnerPreferenceDto): Promise<PartnerPreference>;
   getUserImages(userId: number): Promise<UserImageDto[]>;
   uploadUserImage(userId: number, imageUrl: string): Promise<UserImageDto>;
   deleteUserImage(userId: number, imageId: number): Promise<{ success: boolean }>;
   setPrimaryImage(userId: number, imageId: number): Promise<UserImageDto>;
   completeImageUpload(userId: number): Promise<ImageUploadStatusDto>;
   uploadSelfie(userId: number, frontUrl: string, leftUrl: string, rightUrl: string, latitude?: number, longitude?: number): Promise<{ user: import("@prisma/client").Profile; oldSelfieUrls: { front: string | null; left: string | null; right: string | null } }>;
}
