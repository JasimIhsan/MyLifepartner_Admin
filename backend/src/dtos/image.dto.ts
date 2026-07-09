import { UserImage } from "@prisma/client";

export interface UserImageDto {
   id: number;
   profileId?: number;
   imageUrl: string | null;
   isPrimary: boolean;
   isBlurred?: boolean;
   createdAt?: Date;
}

export const toUserImageDto = (image: UserImage, isBlurred?: boolean): UserImageDto => ({
   id: image.id,
   profileId: image.profileId,
   imageUrl: image.imageUrl,
   isPrimary: image.isPrimary,
   isBlurred,
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
