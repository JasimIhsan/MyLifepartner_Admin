export interface UserInterface {
   id: number;
   mobileNumber: string;
   name: string | null;
   email: string | null;
   isEmailVerified: boolean;
   isBlocked: boolean;
   isDeleted: boolean;
   isProfileCompleted: boolean;
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   createdAt: Date;
   updatedAt: Date;
}

export type SelfieStatus = "PENDING" | "APPROVED" | "REJECTED";
