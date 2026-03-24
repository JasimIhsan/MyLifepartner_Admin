import { Request, Response } from "express";
import { IAdminFeatureService } from "../../interfaces/services/admin.feature.service.interface";
import { createFeatureSchema, updateFeatureSchema } from "../../validators/feature.validator";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";
import { ApiError } from "../../utils/ApiError";

export class AdminFeatureController {
    constructor(private adminFeatureService: IAdminFeatureService) {}

    createFeature = asyncHandler(async (req: Request, res: Response) => {
        const parsed = createFeatureSchema.safeParse(req.body);
        if (!parsed.success) {
            throw new ApiError(400, parsed.error.issues[0].message);
        }

        const feature = await this.adminFeatureService.createFeature(parsed.data);
        res.status(201).json(new ApiResponse(201, feature, "Feature created successfully"));
    });

    getAllFeatures = asyncHandler(async (_req: Request, res: Response) => {
        const features = await this.adminFeatureService.getAllFeatures();
        res.status(200).json(new ApiResponse(200, features, "Features fetched successfully"));
    });

    getFeatureById = asyncHandler(async (req: Request, res: Response) => {
        const id = parseInt(req.params.id as string, 10);
        const feature = await this.adminFeatureService.getFeatureById(id);
        res.status(200).json(new ApiResponse(200, feature, "Feature fetched successfully"));
    });

    updateFeature = asyncHandler(async (req: Request, res: Response) => {
        const id = parseInt(req.params.id as string, 10);
        const parsed = updateFeatureSchema.safeParse(req.body);
        if (!parsed.success) {
            throw new ApiError(400, parsed.error.issues[0].message);
        }

        const feature = await this.adminFeatureService.updateFeature(id, parsed.data);
        res.status(200).json(new ApiResponse(200, feature, "Feature updated successfully"));
    });

    deleteFeature = asyncHandler(async (req: Request, res: Response) => {
        const id = parseInt(req.params.id as string, 10);
        await this.adminFeatureService.deleteFeature(id);
        res.status(200).json(new ApiResponse(200, null, "Feature deleted successfully"));
    });
}
