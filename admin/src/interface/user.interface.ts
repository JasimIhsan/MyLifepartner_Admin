export interface UserInterface {
   id: number;
   mobileNumber: string;
   name: string | null;
   email: string | null;
   isBanned: boolean;
   isSuspended: boolean;
   isFoundingMember: boolean;
   foundingMemberSince?: string | Date | null;
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

export interface ArchivedUserInterface {
   id: number;
   userId: number;
   originalEmail: string;
   originalPhone: string | null;
   originalName: string | null;
   reasonForArchive: string | null;
   archivedAt: string | Date;
}
