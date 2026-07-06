import { ImageAssets, ImageAssetsSection } from "@prisma/client";
import { CreateImageAssetDto, UpdateImageAssetDto, ImageAssetFilters } from "@/dtos/image-asset.dto";
import { IImageAssetRepository } from "../../interfaces/repositories/image-asset.repository.interface";
import { IImageAssetService } from "../../interfaces/services/image-asset.service.interface";
import { IS3Service } from "../../interfaces/services/s3.service.interface";

export class ImageAssetService implements IImageAssetService {
   constructor(
      private readonly imageAssetRepository: IImageAssetRepository,
      private readonly s3Service: IS3Service
   ) {}

   /**
    * Creates a new image asset and optionally uploads a file to S3
    * @param data - The DTO containing the image asset details
    * @param file - Optional Multer file object for S3 upload
    * @returns The created ImageAssets object
    * @throws Error if imageUrl or file is not provided
    */
   async createAsset(data: CreateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets> {
      let imageUrl = data.imageUrl;

      // Handle multipart form data strings (everything is a string in req.body when using form-data)
      const displayOrder = data.displayOrder ? parseInt(data.displayOrder.toString()) : 0;
      const isActive = data.isActive !== undefined ? ((data.isActive as any) === 'true' || data.isActive === true) : true;

      if (file) {
         imageUrl = await this.s3Service.uploadToS3(file, `assets/${data.section.toLowerCase()}`);
      }

      if (!imageUrl) {
         throw new Error("Image URL or file is required");
      }

      return this.imageAssetRepository.create({
         ...data,
         displayOrder: isNaN(displayOrder) ? 0 : displayOrder,
         isActive,
         imageUrl,
      });
   }

   /**
    * Retrieves all image assets based on filters, converting S3 keys to presigned URLs
    * @param filters - Filtering criteria (e.g., section, isActive)
    * @param skip - Number of records to skip
    * @param take - Number of records to take
    * @returns Object containing the assets array and total count
    */
   async getAllAssets(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }> {
      const result = await this.imageAssetRepository.findAll(filters, skip, take);

      // Convert S3 keys to presigned URLs
      const assetsWithUrls = await Promise.all(
         result.assets.map(async (asset) => ({
            ...asset,
            imageUrl: await this.s3Service.getPresignedUrl(asset.imageUrl),
         }))
      );

      return { assets: assetsWithUrls, total: result.total };
   }

   /**
    * Retrieves an image asset by its ID, generating a presigned URL if found
    * @param id - The ID of the asset
    * @returns The ImageAssets object with a presigned URL, or null if not found
    */
   async getAssetById(id: number): Promise<ImageAssets | null> {
      const asset = await this.imageAssetRepository.findById(id);
      if (asset) {
         asset.imageUrl = await this.s3Service.getPresignedUrl(asset.imageUrl);
      }
      return asset;
   }

   /**
    * Retrieves active image assets for a specific section, generating presigned URLs
    * @param section - The section to filter by
    * @returns Array of active ImageAssets with presigned URLs
    */
   async getAssetsBySection(section: ImageAssetsSection): Promise<ImageAssets[]> {
      const assets = await this.imageAssetRepository.findBySection(section, true);

      // Convert S3 keys to presigned URLs
      return Promise.all(
         assets.map(async (asset) => ({
            ...asset,
            imageUrl: await this.s3Service.getPresignedUrl(asset.imageUrl),
         }))
      );
   }

   /**
    * Updates an existing image asset, handling optional new file upload to S3
    * @param id - The ID of the asset to update
    * @param data - The DTO containing updated fields
    * @param file - Optional Multer file object for a new S3 upload
    * @returns The updated ImageAssets object
    * @throws Error if the asset is not found
    */
   async updateAsset(id: number, data: UpdateImageAssetDto, file?: Express.Multer.File): Promise<ImageAssets> {
      const existingAsset = await this.imageAssetRepository.findById(id);
      if (!existingAsset) {
         throw new Error("Asset not found");
      }

      let imageUrl = data.imageUrl as string | undefined;

      // Handle multipart form data strings
      if (data.displayOrder !== undefined) {
         const parsedOrder = parseInt(data.displayOrder.toString());
         data.displayOrder = isNaN(parsedOrder) ? 0 : parsedOrder;
      }
      if (data.isActive !== undefined) {
         data.isActive = (data.isActive as any) === 'true' || data.isActive === true;
      }

      if (file) {
         // Delete old image from S3 if it exists and we're uploading a new one
         if (existingAsset.imageUrl) {
            await this.s3Service.deleteFromS3(existingAsset.imageUrl);
         }
         imageUrl = await this.s3Service.uploadToS3(file, `assets/${existingAsset.section.toLowerCase()}`);
      }

      return this.imageAssetRepository.update(id, {
         ...data,
         imageUrl,
      });
   }

   /**
    * Deletes an image asset and removes its corresponding file from S3 if it exists
    * @param id - The ID of the asset to delete
    */
   async deleteAsset(id: number): Promise<void> {
      const asset = await this.imageAssetRepository.findById(id);
      if (asset) {
         await this.s3Service.deleteFromS3(asset.imageUrl);
         await this.imageAssetRepository.delete(id);
      }
   }
}
