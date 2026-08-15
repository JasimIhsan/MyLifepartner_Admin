import { UserImage } from "@prisma/client";

type UserImageDtoSource = Pick<UserImage, "id" | "profileId" | "isPrimary" | "createdAt"> & {
   imageUrl: string | null;
};

export interface PresignedProfileImageDto {
   imageId: number;
   presignedImageUrl: string | null;
   isBlurred?: boolean;
}

export interface UserImageDto {
   id: number;
   imageId: number;
   profileId?: number;
   imageUrl: string | null;
   presignedImageUrl: string | null;
   isPrimary: boolean;
   isBlurred?: boolean;
   createdAt?: Date;
}

export const toUserImageDto = (image: UserImageDtoSource, isBlurred?: boolean): UserImageDto => ({
   id: image.id,
   imageId: image.id,
   profileId: image.profileId,
   imageUrl: image.imageUrl,
   presignedImageUrl: image.imageUrl,
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
