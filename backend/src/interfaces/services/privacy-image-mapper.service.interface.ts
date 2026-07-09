import { UserImage } from "@prisma/client";

export type PrivacyImageDto = {
   id: number;
   imageUrl: string | null;
   isPrimary: boolean;
   isBlurred: boolean;
};

export type MapImagesParams = {
   viewerUserId: number;
   viewerPrivacyEnabled: boolean;
   targetUserId: number;
   targetPrivacyEnabled: boolean;
   targetBlurredImageUrl: string | null;
   targetImages: Pick<UserImage, "id" | "imageUrl" | "isPrimary">[];
   hasApprovedAccess: boolean;
};

export interface IPrivacyImageMapperService {
   mapImages(params: MapImagesParams): Promise<PrivacyImageDto[]>;
}
