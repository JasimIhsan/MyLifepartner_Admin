import { IAdminSubscriptionService } from "@/interfaces/services/admin.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";
import { addFeaturesSchema, createPlanSchema, updateFeatureSchema, updatePlanSchema } from "@/validators/subscription.validator";

export class AdminSubscriptionController {
   constructor(private adminSubscriptionService: IAdminSubscriptionService) {}

   // ══════════════════════════════════════════════
   // Plan Endpoints
   // ══════════════════════════════════════════════

   /** POST /admin/plans */
   createPlan = asyncHandler(async (req: Request, res: Response) => {
      const parsed = createPlanSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const plan = await this.adminSubscriptionService.createPlan(parsed.data);
      res.status(201).json(new ApiResponse(201, plan, "Subscription plan created successfully"));
   });

   /** GET /admin/plans */
   getPlans = asyncHandler(async (_req: Request, res: Response) => {
      const plans = await this.adminSubscriptionService.getPlans();
      res.status(200).json(new ApiResponse(200, plans, "Subscription plans retrieved successfully"));
   });

   /** GET /admin/plans/:planId */
   getPlanById = asyncHandler(async (req: Request, res: Response) => {
      const planId = parseInt(req.params.planId as string);
      const plan = await this.adminSubscriptionService.getPlanById(planId);
      res.status(200).json(new ApiResponse(200, plan, "Subscription plan retrieved successfully"));
   });

   /** PATCH /admin/plans/:planId */
   updatePlan = asyncHandler(async (req: Request, res: Response) => {
      const planId = parseInt(req.params.planId as string);
      const parsed = updatePlanSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const plan = await this.adminSubscriptionService.updatePlan(planId, parsed.data);
      res.status(200).json(new ApiResponse(200, plan, "Subscription plan updated successfully"));
   });

   /** DELETE /admin/plans/:planId */
   deletePlan = asyncHandler(async (req: Request, res: Response) => {
      const planId = parseInt(req.params.planId as string);
      await this.adminSubscriptionService.deletePlan(planId);
      res.status(200).json(new ApiResponse(200, null, "Subscription plan deleted successfully"));
   });

   // ══════════════════════════════════════════════
   // Feature Endpoints
   // ══════════════════════════════════════════════

   /** POST /admin/plans/:planId/features */
   addFeatures = asyncHandler(async (req: Request, res: Response) => {
      const planId = parseInt(req.params.planId as string);
      const parsed = addFeaturesSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const features = await this.adminSubscriptionService.addFeatures(planId, parsed.data);
      res.status(201).json(new ApiResponse(201, features, "Features added successfully"));
   });

   /** PATCH /admin/features/:featureId */
   updateFeature = asyncHandler(async (req: Request, res: Response) => {
      const featureId = parseInt(req.params.featureId as string);
      const parsed = updateFeatureSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const feature = await this.adminSubscriptionService.updateFeature(featureId, parsed.data.value);
      res.status(200).json(new ApiResponse(200, feature, "Feature updated successfully"));
   });

   /** DELETE /admin/features/:featureId */
   deleteFeature = asyncHandler(async (req: Request, res: Response) => {
      const featureId = parseInt(req.params.featureId as string);
      await this.adminSubscriptionService.deleteFeature(featureId);
      res.status(200).json(new ApiResponse(200, null, "Feature deleted successfully"));
   });
}
