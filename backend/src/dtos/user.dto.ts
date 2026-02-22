import { SelfieStatus, User } from "@prisma/client";

export interface UserDto {
   id: number;
   mobileNumber: string;
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
   isProfileCompleted: user.isProfileCompleted,
   hasCompletedImageUpload: user.hasCompletedImageUpload,
   selfieStatus: user.selfieStatus,
   selfieUrl: user.selfieUrl,
   createdAt: user.createdAt,
   updatedAt: user.updatedAt,
});
