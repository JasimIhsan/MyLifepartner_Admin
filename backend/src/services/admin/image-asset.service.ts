import { CreateImageAssetDto, ImageAssetFilters, UpdateImageAssetDto } from "@/dtos/image-asset.dto";
import { IImageAssetRepository } from "@/interfaces/repositories/image-asset.repository.interface";
import { IImageAssetService } from "@/interfaces/services/image-asset.service.interface";
import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ImageAssets, ImageAssetsSection } from "@/interfaces/services/image-asset.service.interface";

type PaginatedImageAssets = {
   assets: ImageAssets[];
   total: number;
};

const DEFAULT_DISPLAY_ORDER = 0;
const DEFAULT_IS_ACTIVE = true;

export class ImageAssetService implements IImageAssetService {
   constructor(
      private readonly imageAssetRepository: IImageAssetRepository,
      private readonly s3Service: IS3Service
   ) {}

   /**
    * Creates an image asset.
    *
    * @param data - Image asset creation data.
    * @param file - Optional image file.
    * @returns Created image asset.
    */
   async createAsset(data: CreateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets> {
      const imageUrl = file ? await this.s3Service.uploadToS3(file, this.getAssetUploadFolder(data.section as unknown as ImageAssetsSection)) : data.imageUrl;

      if (!imageUrl) {
         throw new ApiError(400, "Image URL or file is required");
      }

      return this.imageAssetRepository.create({
         ...data,
         imageUrl,
         displayOrder: this.parseDisplayOrder(data.displayOrder),
         isActive: this.parseBoolean(data.isActive, DEFAULT_IS_ACTIVE),
      }) as unknown as ImageAssets;
   }

   /**
    * Gets image assets with filters and pagination.
    *
    * @param filters - Image asset filters.
    * @param skip - Number of assets to skip.
    * @param take - Number of assets to fetch.
    * @returns Image assets and total matching count.
    */
   async getAllAssets(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<PaginatedImageAssets> {
      const { assets, total } = await this.imageAssetRepository.findAll(filters, skip, take);

      return {
         assets: (await this.addPresignedUrls(assets as unknown as ImageAssets[])) as unknown as ImageAssets[],
         total,
      };
   }

   /**
    * Gets an image asset by ID.
    *
    * @param id - Image asset ID.
    * @returns Image asset, or null if not found.
    */
   async getAssetById(id: number): Promise<ImageAssets | null> {
      const asset = await this.imageAssetRepository.findById(id);

      if (!asset) {
         return null;
      }

      return this.addPresignedUrl(asset as unknown as ImageAssets);
   }

   /**
    * Gets active image assets by section.
    *
    * @param section - Image asset section.
    * @returns Active image assets.
    */
   async getAssetsBySection(section: ImageAssetsSection): Promise<ImageAssets[]> {
      const assets = await this.imageAssetRepository.findBySection(section, true);

      return this.addPresignedUrls(assets as unknown as ImageAssets[]);
   }

   /**
    * Updates an image asset.
    *
    * @param id - Image asset ID.
    * @param data - Image asset update data.
    * @param file - Optional new image file.
    * @returns Updated image asset.
    */
   async updateAsset(id: number, data: UpdateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets> {
      const existingAsset = await this.getRequiredAsset(id);

      const updateData = this.buildUpdateAssetData(data);

      if (file) {
         await this.s3Service.deleteFromS3(existingAsset.imageUrl);

         updateData.imageUrl = await this.s3Service.uploadToS3(file, this.getAssetUploadFolder(existingAsset.section));
      }

      return this.imageAssetRepository.update(id, updateData) as unknown as ImageAssets;
   }

   /**
    * Deletes an image asset.
    *
    * @param id - Image asset ID.
    * @returns Nothing.
    */
   async deleteAsset(id: number): Promise<void> {
      const asset = await this.getRequiredAsset(id);

      await this.s3Service.deleteFromS3(asset.imageUrl);
      await this.imageAssetRepository.delete(id);
   }

   /**
    * Gets required image asset.
    *
    * @param id - Image asset ID.
    * @returns Image asset.
    */
   private async getRequiredAsset(id: number): Promise<ImageAssets> {
      const asset = await this.imageAssetRepository.findById(id);

      if (!asset) {
         throw new ApiError(404, "Asset not found");
      }

      return asset as unknown as ImageAssets;
   }

   /**
    * Builds image asset update data.
    *
    * @param data - Image asset update data.
    * @returns Normalized update data.
    */
   private buildUpdateAssetData(data: UpdateImageAssetDto): UpdateImageAssetDto {
      return {
         ...data,
         ...(data.displayOrder !== undefined && {
            displayOrder: this.parseDisplayOrder(data.displayOrder),
         }),
         ...(data.isActive !== undefined && {
            isActive: this.parseBoolean(data.isActive),
         }),
      };
   }

   /**
    * Adds presigned URLs to image assets.
    *
    * @param assets - Image assets.
    * @returns Image assets with presigned URLs.
    */
   private async addPresignedUrls(assets: ImageAssets[]): Promise<ImageAssets[]> {
      return Promise.all(assets.map((asset) => this.addPresignedUrl(asset)));
   }

   /**
    * Adds presigned URL to image asset.
    *
    * @param asset - Image asset.
    * @returns Image asset with presigned URL.
    */
   private async addPresignedUrl(asset: ImageAssets): Promise<ImageAssets> {
      return {
         ...asset,
         imageUrl: await this.s3Service.getPresignedUrl(asset.imageUrl),
      };
   }

   /**
    * Gets asset upload folder.
    *
    * @param section - Image asset section.
    * @returns Upload folder path.
    */
   private getAssetUploadFolder(section: ImageAssetsSection): string {
      return `assets/${section.toLowerCase()}`;
   }

   /**
    * Parses display order.
    *
    * @param value - Display order value.
    * @returns Parsed display order.
    */
   private parseDisplayOrder(value: unknown): number {
      const parsedValue = Number(value);

      return Number.isNaN(parsedValue) ? DEFAULT_DISPLAY_ORDER : parsedValue;
   }

   /**
    * Parses boolean value.
    *
    * @param value - Boolean-like value.
    * @param defaultValue - Default boolean value.
    * @returns Parsed boolean.
    */
   private parseBoolean(value: unknown, defaultValue: boolean = false): boolean {
      if (value === undefined || value === null) {
         return defaultValue;
      }

      if (typeof value === "boolean") {
         return value;
      }

      return String(value).toLowerCase() === "true";
   }
}
