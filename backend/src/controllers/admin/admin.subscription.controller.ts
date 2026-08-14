import { IAdminSubscriptionService } from "@/interfaces/services/admin.subscription.service.interface";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { addFeaturesSchema, createPlanSchema, updateFeatureSchema, updatePlanSchema } from "@/validators/subscription.validator";
import { Request, Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource, SubscriptionStatus } from "@prisma/client";

export class AdminSubscriptionController {
   constructor(
      private readonly adminSubscriptionService: IAdminSubscriptionService,
      private readonly userService: IUserService,
      private readonly userSubscriptionService: IUserSubscriptionService
   ) {}

   /**
    * @route POST /api/v1/admin/subscriptions
    * @purpose Creates a new subscription plan.
    */
   public createPlan = asyncHandler(async (req: Request, res: Response) => {
      const parsed = createPlanSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const plan = await this.adminSubscriptionService.createPlan(parsed.data);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "CREATE_PLAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Created subscription plan: ${plan.name}`,
         newValue: plan,
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, plan, "Subscription plan created successfully"));
   });

   /**
    * @route GET /api/v1/admin/subscriptions
    * @purpose Fetches all subscription plans.
    */
   public getPlans = asyncHandler(async (_req: Request, res: Response) => {
      const plans = await this.adminSubscriptionService.getPlans();

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, plans, "Subscription plans retrieved successfully"));
   });

   /**
    * @route GET /api/admin/subscriptions/users
    * @purpose Fetches users with their current subscription state for admin management.
    */
   public getUserSubscriptions = asyncHandler(async (req: Request, res: Response) => {
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;
      const status = typeof req.query.status === "string" ? req.query.status.trim() : undefined;
      const pageNumber = req.query.page ? Number(req.query.page) : undefined;
      const limitNumber = req.query.limit ? Number(req.query.limit) : undefined;
      const planId = req.query.planId ? Number(req.query.planId) : undefined;

      if (pageNumber !== undefined && (!Number.isInteger(pageNumber) || pageNumber <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid page number");
      }

      if (limitNumber !== undefined && (!Number.isInteger(limitNumber) || limitNumber <= 0 || limitNumber > 100)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid limit number");
      }

      if (planId !== undefined && (!Number.isInteger(planId) || planId <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      const allowedStatuses = new Set(["ALL", "NO_ACTIVE_SUBSCRIPTION", ...Object.values(SubscriptionStatus)]);
      if (status && !allowedStatuses.has(status)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid subscription status");
      }

      const { data, total } = await this.userService.getSubscriptionUsers({
         search,
         page: pageNumber,
         limit: limitNumber,
         status,
         planId,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "User subscriptions retrieved successfully"));
   });

   /**
    * @route PATCH /api/admin/subscriptions/users/:userId/plan
    * @purpose Manually changes a user's subscription plan.
    */
   public updateUserSubscriptionPlan = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.userId);
      const planId = Number(req.body?.planId);
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      const subscription = await this.userSubscriptionService.adminChangeUserSubscriptionPlan(userId, planId);

      await auditService.log({
         userId,
         adminId: Number.isInteger(adminId) && adminId > 0 ? adminId : undefined,
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "ADMIN_CHANGE_USER_SUBSCRIPTION_PLAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin changed user ID: ${userId} subscription to ${subscription.plan?.name ?? "selected"} plan`,
         newValue: {
            subscriptionId: subscription.id,
            planId: subscription.planId,
            planName: subscription.plan?.name,
            status: subscription.status,
            endDate: subscription.endDate,
         },
         entityType: "UserSubscription",
         entityId: subscription.id.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, subscription, "User subscription plan updated successfully"));
   });

   /**
    * @route GET /api/v1/admin/subscriptions/:planId
    * @purpose Fetches subscription plan details by ID.
    */
   public getPlanById = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      const plan = await this.adminSubscriptionService.getPlanById(planId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, plan, "Subscription plan retrieved successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/subscriptions/:planId
    * @purpose Updates a subscription plan by ID.
    */
   public updatePlan = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      const parsed = updatePlanSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const plan = await this.adminSubscriptionService.updatePlan(planId, parsed.data);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "UPDATE_PLAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Updated subscription plan ID: ${planId}`,
         newValue: parsed.data,
         entityType: "SubscriptionPlan",
         entityId: planId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, plan, "Subscription plan updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/subscriptions/:planId
    * @purpose Deletes a subscription plan by ID.
    */
   public deletePlan = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      await this.adminSubscriptionService.deletePlan(planId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "DELETE_PLAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `Deleted subscription plan ID: ${planId}`,
         entityType: "SubscriptionPlan",
         entityId: planId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Subscription plan deleted successfully"));
   });

   /**
    * @route POST /api/v1/admin/subscriptions/:planId/features
    * @purpose Adds features to a subscription plan.
    */
   public addFeatures = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      const parsed = addFeaturesSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const features = await this.adminSubscriptionService.addFeatures(planId, parsed.data);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "ADD_PLAN_FEATURES",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Added features to plan ID: ${planId}`,
         newValue: parsed.data,
         entityType: "SubscriptionPlan",
         entityId: planId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, features, "Features added successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/subscriptions/:planId/features/:featureId
    * @purpose Updates a feature inside a subscription plan.
    */
   public updatePlanFeature = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);
      const planFeatureId = Number(req.params.featureId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      if (!Number.isInteger(planFeatureId) || planFeatureId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid feature ID");
      }

      const parsed = updateFeatureSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const feature = await this.adminSubscriptionService.updatePlanFeature(planFeatureId, parsed.data);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "UPDATE_PLAN_FEATURE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Updated plan feature ID: ${planFeatureId}`,
         newValue: parsed.data,
         entityType: "PlanFeature",
         entityId: planFeatureId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, feature, "Plan feature updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/subscriptions/:planId/features/:featureId
    * @purpose Deletes a feature from a subscription plan.
    */
   public deletePlanFeature = asyncHandler(async (req: Request, res: Response) => {
      const planId = Number(req.params.planId);
      const planFeatureId = Number(req.params.featureId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid plan ID");
      }

      if (!Number.isInteger(planFeatureId) || planFeatureId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid feature ID");
      }

      await this.adminSubscriptionService.deletePlanFeature(planFeatureId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "DELETE_PLAN_FEATURE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `Deleted plan feature ID: ${planFeatureId}`,
         entityType: "PlanFeature",
         entityId: planFeatureId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Plan feature deleted successfully"));
   });
}
