import { ImageAssets, ImageAssetsSection, Prisma } from "@prisma/client";

export interface IImageAssetService {
   createAsset(data: Prisma.ImageAssetsCreateInput, file?: Express.Multer.File): Promise<ImageAssets>;
   getAllAssets(filters?: Prisma.ImageAssetsWhereInput, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }>;
   getAssetById(id: number): Promise<ImageAssets | null>;
   getAssetsBySection(section: ImageAssetsSection): Promise<ImageAssets[]>;
   updateAsset(id: number, data: Prisma.ImageAssetsUpdateInput, file?: Express.Multer.File): Promise<ImageAssets>;
   deleteAsset(id: number): Promise<void>;
}
