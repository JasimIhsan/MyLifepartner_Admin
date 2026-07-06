import { CreateImageAssetDto, UpdateImageAssetDto, ImageAssetFilters } from "@/dtos/image-asset.dto";

export enum ImageAssetsSection {
   ONBOARDING_SCREEN = "ONBOARDING_SCREEN",
   BANNERS = "BANNERS",
   ADS = "ADS",
   ONBOARDING = "ONBOARDING",
   ICON = "ICON",
}

export interface ImageAssets {
   id: number;
   section: ImageAssetsSection;
   title: string;
   imageUrl: string;
   altText: string | null;
   redirectUrl: string | null;
   displayOrder: number;
   isActive: boolean;
   createdAt: Date;
   updatedAt: Date;
}


export interface IImageAssetService {
   createAsset(data: CreateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets>;
   getAllAssets(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }>;
   getAssetById(id: number): Promise<ImageAssets | null>;
   getAssetsBySection(section: ImageAssetsSection): Promise<ImageAssets[]>;
   updateAsset(id: number, data: UpdateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets>;
   deleteAsset(id: number): Promise<void>;
}
