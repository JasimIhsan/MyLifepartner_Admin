import { ImageAssetsSection } from "@prisma/client";

export interface CreateImageAssetDto {
   title: string;
   section: ImageAssetsSection;
   imageUrl: string;
   displayOrder?: number;
   isActive?: boolean;
}

export interface UpdateImageAssetDto {
   title?: string;
   section?: ImageAssetsSection;
   imageUrl?: string;
   displayOrder?: number;
   isActive?: boolean;
}

export interface ImageAssetFilters {
   section?: ImageAssetsSection;
   isActive?: boolean;
}
