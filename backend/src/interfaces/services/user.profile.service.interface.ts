import { ImageUploadStatusDto, UserImageDto } from "@/dtos/image.dto";
import { ProfileQuestionDto, ProfileSectionDto, ProfileStatusDto, UserAnswerDto } from "@/dtos/profile.dto";
import { UpdateProfileDto, CreatePartnerPreferenceDto } from "@/dtos/profile.input.dto";

export enum ProfileStatus {
   INCOMPLETE = "INCOMPLETE",
   ONBOARDING_COMPLETED = "ONBOARDING_COMPLETED",
   COMPLETED = "COMPLETED",
}

export interface Profile {
   id: number;
   userId: number;
   name: string | null;
   gender: string | null;
   dateOfBirth: Date | null;
   maritalStatus: string | null;
   heightCm: number | null;
   motherTongue: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   lastLocationLat: number | null;
   lastLocationLng: number | null;
   highestEducation: string | null;
   occupation: string | null;
   bio: string | null;
   languages: string[];
   childrenStatus: string | null;
   emotionalReadiness: string | null;
   lookingFor: string | null;
   relationshipTimeline: string | null;
   smokingHabit: string | null;
   drinkingHabit: string | null;
   profileCompletion: number;
   profileStatus: ProfileStatus;
   hasCompletedBasicDetails: boolean;
   hasCompletedPartnerPreference: boolean;
   hasCompletedImageUpload: boolean;
   selfieUrl: string | null;
   leftSelfieUrl: string | null;
   rightSelfieUrl: string | null;
   selfieStatus: string | null;
}

export interface PartnerPreference {
   id: number;
   userId: number;
   ageFrom: number | null;
   ageTo: number | null;
   heightFrom: number | null;
   heightTo: number | null;
   maritalStatus: string[];
   motherTongue: string[];
   highestEducation: string[];
   occupation: string[];
}

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
   uploadUserImage(userId: number, file: Express.Multer.File): Promise<UserImageDto>;
   replaceUserImage(userId: number, imageId: number, file: Express.Multer.File): Promise<UserImageDto>;
   setPrimaryImage(userId: number, imageId: number): Promise<UserImageDto>;
   completeImageUpload(userId: number): Promise<ImageUploadStatusDto>;
   uploadSelfie(userId: number, frontFile: Express.Multer.File, leftFile: Express.Multer.File, rightFile: Express.Multer.File, latitude?: number, longitude?: number): Promise<{ user: Profile }>;
   updatePrivacySettings(userId: number, privacyEnabled: boolean): Promise<{ privacyEnabled: boolean }>;
}
