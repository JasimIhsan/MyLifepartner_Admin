import { PartnerPreference, Profile, ProfileQuestion, ProfileSection, ProfileStatus, UserAnswer, UserImage } from "@prisma/client";
import { UpdateProfileDto, CreatePartnerPreferenceDto } from "@/dtos/profile.input.dto";

export interface IProfileRepository {
   getProfileStructure(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]>;
   getSections(isPrimary?: boolean): Promise<ProfileSection[]>;
   getQuestionsBySectionByOrder(sectionOrder: number, userId: number): Promise<(ProfileQuestion & { section: ProfileSection; answers: UserAnswer[] })[]>;
   getUserAnswers(userId: number): Promise<UserAnswer[]>;
   saveAnswer(userId: number, questionId: number, answer: unknown, score?: number): Promise<UserAnswer>;
   updateProfileStatus(userId: number, status: ProfileStatus): Promise<Profile>;
   getRequiredQuestionsCount(isPrimary?: boolean): Promise<number>;
   getUserAnsweredCount(userId: number, isPrimary?: boolean): Promise<number>;
   updateBasicProfile(userId: number, data: UpdateProfileDto): Promise<Profile>;
   updatePartnerPreference(userId: number, data: CreatePartnerPreferenceDto): Promise<PartnerPreference>;
   getUserImages(userId: number): Promise<UserImage[]>;
   getUserImagesCount(userId: number): Promise<number>;
   getUserImageById(id: number): Promise<(UserImage & { profile: Profile }) | null>;
   saveUserImage(userId: number, imageUrl: string, isPrimary?: boolean): Promise<UserImage>;
   deleteUserImage(id: number): Promise<UserImage>;
   unsetPrimaryImages(userId: number): Promise<{ count: number }>;
   setImageAsPrimary(id: number): Promise<UserImage>;
   completeImageUpload(userId: number): Promise<Profile>;
   saveSelfie(userId: number, frontUrl: string, leftUrl: string, rightUrl: string, latitude?: number, longitude?: number): Promise<{ user: Profile; oldSelfieUrls: { front: string | null; left: string | null; right: string | null } }>;
}
