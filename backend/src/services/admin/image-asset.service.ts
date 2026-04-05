import { ImageAssets, ImageAssetsSection, Prisma } from "@prisma/client";
import { IImageAssetRepository } from "../../interfaces/repositories/image-asset.repository.interface";
import { IImageAssetService } from "../../interfaces/services/image-asset.service.interface";
import { IS3Service } from "../../interfaces/services/s3.service.interface";

export class ImageAssetService implements IImageAssetService {
   constructor(
      private readonly imageAssetRepository: IImageAssetRepository,
      private readonly s3Service: IS3Service
   ) {}

   async createAsset(data: any, file?: Express.Multer.File): Promise<ImageAssets> {
      let imageUrl = data.imageUrl;

      // Handle multipart form data strings (everything is a string in req.body when using form-data)
      const displayOrder = data.displayOrder ? parseInt(data.displayOrder.toString()) : 0;
      const isActive = data.isActive === 'true' || data.isActive === true;

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

   async getAllAssets(filters?: Prisma.ImageAssetsWhereInput, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }> {
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

   async getAssetById(id: number): Promise<ImageAssets | null> {
      const asset = await this.imageAssetRepository.findById(id);
      if (asset) {
         asset.imageUrl = await this.s3Service.getPresignedUrl(asset.imageUrl);
      }
      return asset;
   }

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

   async updateAsset(id: number, data: any, file?: Express.Multer.File): Promise<ImageAssets> {
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
         data.isActive = data.isActive === 'true' || data.isActive === true;
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

   async deleteAsset(id: number): Promise<void> {
      const asset = await this.imageAssetRepository.findById(id);
      if (asset) {
         await this.s3Service.deleteFromS3(asset.imageUrl);
         await this.imageAssetRepository.delete(id);
      }
   }
}
