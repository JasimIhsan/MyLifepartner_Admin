import { ImageAssets, ImageAssetsSection, Prisma } from "@prisma/client";

export interface IImageAssetRepository {
   create(data: Prisma.ImageAssetsCreateInput): Promise<ImageAssets>;
   findAll(where?: Prisma.ImageAssetsWhereInput, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }>;
   findById(id: number): Promise<ImageAssets | null>;
   findBySection(section: ImageAssetsSection, isActive?: boolean): Promise<ImageAssets[]>;
   update(id: number, data: Prisma.ImageAssetsUpdateInput): Promise<ImageAssets>;
   delete(id: number): Promise<ImageAssets>;
}
