import { IAdminFeatureService } from "@/interfaces/services/admin.feature.service.interface";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class AdminFeatureController {
   constructor(private readonly adminFeatureService: IAdminFeatureService) {}

   /**
    * @route GET /api/v1/admin/features
    * @purpose Fetches all available features.
    */
   public getAllFeatures = asyncHandler(async (_req: Request, res: Response) => {
      const features = await this.adminFeatureService.getAllFeatures();

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, features, "Features fetched successfully"));
   });
}
