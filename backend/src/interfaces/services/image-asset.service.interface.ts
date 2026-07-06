import { ImageAssets, ImageAssetsSection } from "@prisma/client";
import { CreateImageAssetDto, UpdateImageAssetDto, ImageAssetFilters } from "@/dtos/image-asset.dto";

export interface IImageAssetService {
   createAsset(data: CreateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets>;
   getAllAssets(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }>;
   getAssetById(id: number): Promise<ImageAssets | null>;
   getAssetsBySection(section: ImageAssetsSection): Promise<ImageAssets[]>;
   updateAsset(id: number, data: UpdateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets>;
   deleteAsset(id: number): Promise<void>;
}
