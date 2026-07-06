import { IImageAssetService, ImageAssetsSection } from "@/interfaces/services/image-asset.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

type ImageAssetFilters = {
   section?: ImageAssetsSection;
};

export class ImageAssetController {
   constructor(private readonly imageAssetService: IImageAssetService) {}

   /**
    * @route POST /api/v1/admin/image-assets
    * @purpose Creates a new image asset.
    */
   public createAsset = asyncHandler(async (req: Request, res: Response) => {
      const asset = await this.imageAssetService.createAsset(req.body, req.file);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, asset, "Image asset created successfully"));
   });

   /**
    * @route GET /api/v1/admin/image-assets
    * @purpose Fetches all image assets with optional filters.
    */
   public getAllAssets = asyncHandler(async (req: Request, res: Response) => {
      const { section } = req.query;
      const skip = req.query.skip ? Number(req.query.skip) : undefined;
      const take = req.query.take ? Number(req.query.take) : undefined;

      if (skip !== undefined && (!Number.isInteger(skip) || skip < 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid skip value");
      }

      if (take !== undefined && (!Number.isInteger(take) || take <= 0 || take > 100)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid take value");
      }

      const filters: ImageAssetFilters = {};

      if (section !== undefined) {
         if (typeof section !== "string" || !this.isValidSection(section)) {
            throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image asset section");
         }

         filters.section = section;
      }

      const result = await this.imageAssetService.getAllAssets(filters, skip, take);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Image assets fetched successfully"));
   });

   /**
    * @route GET /api/v1/admin/image-assets/section/:section
    * @purpose Fetches image assets by section.
    */
   public getAssetsBySection = asyncHandler(async (req: Request, res: Response) => {
      const section = req.params.section;

      if (typeof section !== "string" || !this.isValidSection(section)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image asset section");
      }

      const assets = await this.imageAssetService.getAssetsBySection(section);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, assets, "Image assets fetched successfully"));
   });

   /**
    * @route PUT /api/v1/admin/image-assets/:id
    * @purpose Updates an image asset by ID.
    */
   public updateAsset = asyncHandler(async (req: Request, res: Response) => {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image asset ID");
      }

      const asset = await this.imageAssetService.updateAsset(id, req.body, req.file);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, asset, "Image asset updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/image-assets/:id
    * @purpose Deletes an image asset by ID.
    */
   public deleteAsset = asyncHandler(async (req: Request, res: Response) => {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image asset ID");
      }

      await this.imageAssetService.deleteAsset(id);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Image asset deleted successfully"));
   });

   /**
    * Checks whether image asset section is valid.
    */
   private isValidSection(section: string): section is ImageAssetsSection {
      return Object.values(ImageAssetsSection).includes(section as ImageAssetsSection);
   }
}
