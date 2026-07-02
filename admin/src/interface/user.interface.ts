export interface UserInterface {
   id: number;
   mobileNumber: string;
   name: string | null;
   email: string | null;
   isBlocked: boolean;
   isDeleted: boolean;
   profileStatus: "INCOMPLETE" | "ONBOARDING_COMPLETED" | "COMPLETED";
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   leftSelfieUrl?: string | null;
   rightSelfieUrl?: string | null;
   lastLocationLat?: number | null;
   lastLocationLng?: number | null;
   primaryImageUrl?: string | null;

   // Profile demographics
   gender?: string | null;
   dateOfBirth?: Date | null;
   maritalStatus?: string | null;
   heightCm?: number | null;
   caste?: string | null;
   motherTongue?: string | null;
   city?: string | null;
   state?: string | null;
   country?: string | null;
   highestEducation?: string | null;
   occupation?: string | null;
   bio?: string | null;
   profileCompletion?: number | null;

   createdAt: Date;
   updatedAt: Date;
}

export type SelfieStatus = "PENDING" | "APPROVED" | "REJECTED";
