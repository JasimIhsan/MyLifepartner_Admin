import { PartnerPreference, Profile, ProfileStatus, SelfieStatus, User, Job, PrivacySettings } from "@prisma/client";

export interface UserDto {
   id: number;
   mobileNumber?: string | null;
   name: string | null;
   email: string | null;
   role: string;
   isBanned: boolean;
   isSuspended: boolean;
   bannedAt: Date | null;
   suspendedAt: Date | null;
   isDeleted: boolean;
   profileStatus: ProfileStatus;
   hasCompletedBasicDetails: boolean;
   hasCompletedImageUpload: boolean;
   hasCompletedPartnerPreference: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   primaryImageUrl?: string | null;
   privacyEnabled?: boolean;

   // Profile demographics
   gender?: string | null;
   dateOfBirth?: Date | null;
   maritalStatus?: string | null;
   motherTongue?: string | null;
   city?: string | null;
   state?: string | null;
   country?: string | null;
   highestEducation?: string | null;
   occupation?: string | null;
   bio?: string | null;
   childrenStatus?: string | null;
   lookingFor?: string | null;
   smokingHabit?: string | null;
   drinkingHabit?: string | null;
   languages?: string[];
   profileCompletion?: number | null;

   createdAt: Date;
   updatedAt: Date;
}

export const toUserDto = (user: User & { profile?: (Profile & { job?: Job | null; images?: { isPrimary: boolean; imageUrl: string }[] }) | null; partnerPreference?: PartnerPreference | null; privacySettings?: PrivacySettings | null }): UserDto => ({
   id: user.id,
   mobileNumber: user.mobileNumber,
   name: user.profile?.name || null,
   email: user.email,
   role: user.role,
   isBanned: user.isBanned,
   isSuspended: user.isSuspended,
   bannedAt: user.bannedAt,
   suspendedAt: user.suspendedAt,
   isDeleted: user.isDeleted,
   profileStatus: user.profile?.profileStatus || ProfileStatus.INCOMPLETE,
   hasCompletedBasicDetails: user.profile?.hasCompletedBasicDetails || false,
   hasCompletedImageUpload: user.profile?.hasCompletedImageUpload || false,
   hasCompletedPartnerPreference: user.profile?.hasCompletedPartnerPreference || false,
   selfieStatus: user.profile?.selfieStatus || null,
   selfieUrl: user.profile?.selfieUrl || null,
   primaryImageUrl: user.profile?.images?.find((img) => img.isPrimary)?.imageUrl || null,
   privacyEnabled: user.privacySettings?.privacyEnabled ?? false,

   gender: user.profile?.gender || null,
   dateOfBirth: user.profile?.dateOfBirth || null,
   maritalStatus: user.profile?.maritalStatus || null,
   motherTongue: user.profile?.motherTongue || null,
   city: user.profile?.city || null,
   state: user.profile?.state || null,
   country: user.profile?.country || null,
   highestEducation: user.profile?.highestEducation || null,
   occupation: user.profile?.job?.name || null,
   bio: user.profile?.bio || null,
   childrenStatus: user.profile?.childrenStatus || null,
   lookingFor: user.profile?.lookingFor || null,
   smokingHabit: user.profile?.smokingHabit || null,
   drinkingHabit: user.profile?.drinkingHabit || null,
   languages: user.profile?.languages || [],
   profileCompletion: user.profile?.profileCompletion || null,

   createdAt: user.createdAt,
   updatedAt: user.updatedAt,
});

export type UserSelfieDataDto = {
   url: string | null;
   leftUrl: string | null;
   rightUrl: string | null;
   locationLat: number | null;
   locationLng: number | null;
};

export type UserImageDataDto = {
   id: number;
   imageUrl: string;
   isPrimary: boolean;
   url: string;
};
