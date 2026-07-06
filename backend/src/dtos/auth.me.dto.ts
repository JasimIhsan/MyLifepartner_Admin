export type ProfileStatusType = "INCOMPLETE" | "ONBOARDING_COMPLETED" | "COMPLETED";
export type SelfieStatusType = "PENDING" | "APPROVED" | "REJECTED";

export interface UserOnboardingStatusDto {
   id: number;
   hasCompletedBasicDetails: boolean;
   hasCompletedPartnerPreference: boolean;
   profileStatus: ProfileStatusType;
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatusType | null;
}

