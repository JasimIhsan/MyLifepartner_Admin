import { SelfieStatus, User } from "@prisma/client";

export interface UserDto {
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

export const toUserDto = (user: User): UserDto => ({
   id: user.id,
   mobileNumber: user.mobileNumber,
   name: user.name,
   email: user.email,
   isEmailVerified: user.isEmailVerified,
   isBlocked: user.isBlocked,
   isDeleted: user.isDeleted,
   isProfileCompleted: user.isProfileCompleted,
   hasCompletedImageUpload: user.hasCompletedImageUpload,
   selfieStatus: user.selfieStatus,
   selfieUrl: user.selfieUrl,
   createdAt: user.createdAt,
   updatedAt: user.updatedAt,
});
