import { toSubscriptionPlanDto, toUserSubscriptionDto } from "@/dtos/subscription.dto";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import logger from "@/utils/logger";
import { Request, Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

type CallType = "audio" | "video";

export class UserSubscriptionController {
   constructor(
      private readonly userSubscriptionService: IUserSubscriptionService,
      private readonly userFeatureService: IUserFeatureService
   ) {}

   /**
    * @route GET /api/v1/user/subscriptions/plans
    * @purpose Fetches available subscription plans.
    */
   public getPlans = asyncHandler(async (_req: Request, res: Response) => {
      const plans = await this.userSubscriptionService.getPlans();
      const planDtos = plans.map(toSubscriptionPlanDto);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, planDtos, "Subscription plans retrieved successfully"));
   });

   /**
    * @route GET /api/v1/user/subscriptions/my-subscription
    * @purpose Fetches authenticated user's current subscription.
    */
   public getMySubscription = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const subscription = await this.userSubscriptionService.getMySubscription(userId);
      logger.debug(`Subscription: `, subscription);
      const subscriptionDto = subscription ? toUserSubscriptionDto(subscription) : null;

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, subscriptionDto, "Current subscription retrieved successfully"));
   });

   /**
    * @route GET /api/v1/user/subscriptions/features
    * @purpose Fetches authenticated user's available features.
    */
   public getUserFeatures = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const features = await this.userSubscriptionService.getUserFeatures(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, features, "Current features retrieved successfully"));
   });

   /**
    * @route POST /api/v1/user/subscriptions/subscribe
    * @purpose Subscribes authenticated user to a plan.
    */
   public subscribe = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const planId = Number(req.body.planId);

      if (!Number.isInteger(planId) || planId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Valid plan ID is required");
      }

      const subscription = await this.userSubscriptionService.subscribe(userId, planId);
      const subscriptionDto = toUserSubscriptionDto(subscription);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.SUBSCRIPTION,
         action: "SUBSCRIBE_TO_PLAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User subscribed to plan ID: ${planId}`,
         newValue: subscriptionDto as unknown as Record<string, any>,
         entityType: "UserSubscription",
         entityId: subscription.id.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, subscriptionDto, "Subscribed successfully"));
   });

   /**
    * @route POST /api/v1/user/subscriptions/verify-purchase
    * @purpose Verifies a RevenueCat purchase and immediately activates the plan.
    *
    * Called by the Flutter app right after Purchases.purchasePackage() succeeds.
    * The backend verifies the transaction with the RC REST API and activates the
    * subscription instantly — without waiting for a webhook.
    */
   public verifyPurchase = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const { originalTransactionId, productId, store, environment } = req.body;

      if (!originalTransactionId || typeof originalTransactionId !== "string" || originalTransactionId.trim() === "") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "originalTransactionId is required");
      }

      if (!productId || typeof productId !== "string" || productId.trim() === "") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "productId is required");
      }

      if (!store || typeof store !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "store is required");
      }

      const subscription = await this.userSubscriptionService.verifyAndActivatePurchase(userId, {
         originalTransactionId: originalTransactionId.trim(),
         productId: productId.trim(),
         store: store.trim(),
         environment: (environment ?? "PRODUCTION").trim(),
      });

      const subscriptionDto = toUserSubscriptionDto(subscription);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.SUBSCRIPTION,
         action: "VERIFY_PURCHASE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User verified purchase for product: ${productId}`,
         newValue: { productId, store, environment, originalTransactionId },
         entityType: "UserSubscription",
         entityId: subscription.id.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, subscriptionDto, "Purchase verified and plan activated successfully"));
   });

   /**
    * @route POST /api/v1/user/subscriptions/check-call
    * @purpose Checks whether authenticated user can start or continue a call.
    */
   public checkCallAccess = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const { type } = req.body;

      if (type !== "audio" && type !== "video") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Call type must be audio or video");
      }

      const consumeSeconds = req.body.consumeSeconds === undefined || req.body.consumeSeconds === null ? undefined : Number(req.body.consumeSeconds);

      if (consumeSeconds !== undefined && (!Number.isFinite(consumeSeconds) || consumeSeconds < 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid consume seconds");
      }

      const targetUserId = req.body.targetUserId === undefined || req.body.targetUserId === null ? undefined : Number(req.body.targetUserId);

      if (targetUserId !== undefined && (!Number.isInteger(targetUserId) || targetUserId <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid target user ID");
      }

      await this.userFeatureService.checkCallAccess(userId, type as CallType, consumeSeconds, targetUserId);

      if (consumeSeconds && consumeSeconds > 0) {
         await auditService.log({
            userId,
            actorType: ActorType.USER,
            module: AuditModule.CALL,
            action: "CONSUME_CALL_MINUTES",
            status: AuditStatus.SUCCESS,
            severity: AuditSeverity.INFO,
            message: `User consumed ${consumeSeconds} seconds for ${type} call`,
            newValue: { type, consumeSeconds, targetUserId },
            entityType: "User",
            entityId: userId.toString(),
            source: AuditSource.API,
         });
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Call allowed"));
   });

   /**
    * @route POST /api/v1/user/subscriptions/sync
    * @purpose Syncs authenticated user's subscription from RevenueCat.
    */
   public sync = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const subscription = await this.userSubscriptionService.syncSubscription(userId);
      const features = await this.userSubscriptionService.getUserFeatures(userId);

      const responseData = {
         subscription: subscription ? toUserSubscriptionDto(subscription) : null,
         features,
         syncStatus: subscription?.plan?.name === "FREE" ? "DOWNGRADED" : "SYNCED",
      };

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, responseData, "Subscription synced successfully"));
   });

   /**
    * @route POST /api/v1/user/subscriptions/webhook
    * @purpose Handles RevenueCat subscription webhook events.
    */
   public webhook = asyncHandler(async (req: Request, res: Response) => {
      const signatureHeader = typeof req.headers.authorization === "string" ? req.headers.authorization : "";

      await this.userSubscriptionService.handleWebhook(req.body, signatureHeader);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Webhook handled successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: Request): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }
}
