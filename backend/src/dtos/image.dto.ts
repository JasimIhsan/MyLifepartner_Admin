import { UserImage } from "@prisma/client";

export interface UserImageDto {
   id: number;
   profileId: number;
   imageUrl: string;
   isPrimary: boolean;
   createdAt: Date;
}

export const toUserImageDto = (image: UserImage): UserImageDto => ({
   id: image.id,
   profileId: image.profileId,
   imageUrl: image.imageUrl,
   isPrimary: image.isPrimary,
   createdAt: image.createdAt,
});

export interface ImageUploadStatusDto {
   success: boolean;
   hasCompletedImageUpload: boolean;
}

export const toImageUploadStatusDto = (success: boolean, hasCompletedImageUpload: boolean): ImageUploadStatusDto => ({
   success,
   hasCompletedImageUpload,
});
