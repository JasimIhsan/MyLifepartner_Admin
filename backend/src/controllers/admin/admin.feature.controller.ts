import { Request, Response } from "express";
import { IAdminFeatureService } from "../../interfaces/services/admin.feature.service.interface";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

export class AdminFeatureController {
   constructor(private adminFeatureService: IAdminFeatureService) {}

   getAllFeatures = asyncHandler(async (_req: Request, res: Response) => {
      const features = await this.adminFeatureService.getAllFeatures();
      res.status(200).json(new ApiResponse(200, features, "Features fetched successfully"));
   });
}
