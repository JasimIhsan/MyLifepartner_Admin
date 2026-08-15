import { ImageAccessRequest, ImageAccessStatus, Profile, UserImage } from "@prisma/client";

export type ImageAccessRequestWithProfile = ImageAccessRequest & {
   requester?: {
      profile: (Profile & { images: UserImage[] }) | null;
   } | null;
   owner?: {
      profile: (Profile & { images: UserImage[] }) | null;
   } | null;
};

export type ImageAccessRequestResponseDto = {
   id: number;
   ownerUserId: number;
   requesterUserId: number;
   status: ImageAccessStatus;
   requestedAt: Date;
   respondedAt: Date | null;
   requesterProfile?: {
      name: string | null;
      age: number | null;
      imageId: number | null;
      imageUrl: string | null;
      presignedImageUrl: string | null;
   } | null;
   ownerProfile?: {
      name: string | null;
      age: number | null;
      imageId: number | null;
      imageUrl: string | null;
      presignedImageUrl: string | null;
   } | null;
};
