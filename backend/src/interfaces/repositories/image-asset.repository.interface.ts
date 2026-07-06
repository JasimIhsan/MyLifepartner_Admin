import { ImageAssets, ImageAssetsSection } from "@prisma/client";
import { CreateImageAssetDto, UpdateImageAssetDto, ImageAssetFilters } from "@/dtos/image-asset.dto";

export interface IImageAssetRepository {
   create(data: CreateImageAssetDto): Promise<ImageAssets>;
   findAll(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }>;
   findById(id: number): Promise<ImageAssets | null>;
   findBySection(section: ImageAssetsSection, isActive?: boolean): Promise<ImageAssets[]>;
   update(id: number, data: UpdateImageAssetDto): Promise<ImageAssets>;
   delete(id: number): Promise<ImageAssets>;
}
