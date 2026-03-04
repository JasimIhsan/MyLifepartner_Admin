import { Profile, ProfileStatus, SelfieStatus, User } from "@prisma/client";

export interface UserDto {
   id: number;
   mobileNumber: string;
   name: string | null;
   email: string | null;
   isEmailVerified: boolean;
   isBlocked: boolean;
   isDeleted: boolean;
   profileStatus: ProfileStatus;
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   primaryImageUrl?: string | null;

   // Profile demographics
   gender?: string | null;
   dateOfBirth?: Date | null;
   maritalStatus?: string | null;
   heightCm?: number | null;
   religion?: string | null;
   caste?: string | null;
   motherTongue?: string | null;
   city?: string | null;
   state?: string | null;
   country?: string | null;
   highestEducation?: string | null;
   occupation?: string | null;
   annualIncome?: number | null;
   bio?: string | null;
   profileCompletion?: number | null;

   createdAt: Date;
   updatedAt: Date;
}

export const toUserDto = (user: User & { profile?: Profile | null }): UserDto => ({
   id: user.id,
   mobileNumber: user.mobileNumber,
   name: user.profile?.name || null,
   email: user.email,
   isEmailVerified: user.isEmailVerified,
   isBlocked: user.isBlocked,
   isDeleted: user.isDeleted,
   profileStatus: user.profile?.profileStatus || ProfileStatus.INCOMPLETE,
   hasCompletedImageUpload: user.profile?.hasCompletedImageUpload || false,
   selfieStatus: user.profile?.selfieStatus || null,
   selfieUrl: user.profile?.selfieUrl || null,
   primaryImageUrl: (user.profile as any)?.images?.find((img: any) => img.isPrimary)?.imageUrl || null,

   gender: user.profile?.gender || null,
   dateOfBirth: user.profile?.dateOfBirth || null,
   maritalStatus: user.profile?.maritalStatus || null,
   heightCm: user.profile?.heightCm || null,
   religion: user.profile?.religion || null,
   caste: user.profile?.caste || null,
   motherTongue: user.profile?.motherTongue || null,
   city: user.profile?.city || null,
   state: user.profile?.state || null,
   country: user.profile?.country || null,
   highestEducation: user.profile?.highestEducation || null,
   occupation: user.profile?.occupation || null,
   annualIncome: user.profile?.annualIncome || null,
   bio: user.profile?.bio || null,
   profileCompletion: user.profile?.profileCompletion || null,

   createdAt: user.createdAt,
   updatedAt: user.updatedAt,
});
