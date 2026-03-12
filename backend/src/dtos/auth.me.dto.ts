import { ProfileStatus, SelfieStatus } from "@prisma/client";

export interface UserOnboardingStatusDto {
   id: number;
   hasCompletedBasicDetails: boolean;
   hasCompletedPartnerPreference: boolean;
   profileStatus: ProfileStatus;
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatus | null;
}

