import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

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

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, plans, "Subscription plans retrieved successfully"));
   });

   /**
    * @route GET /api/v1/user/subscriptions/my-subscription
    * @purpose Fetches authenticated user's current subscription.
    */
   public getMySubscription = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const subscription = await this.userSubscriptionService.getMySubscription(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, subscription, "Current subscription retrieved successfully"));
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

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, subscription, "Subscribed successfully"));
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
         subscription,
         features,
         syncStatus: subscription?.plan?.name === "FREE" ? "DOWNGRADED" : "SYNCED"
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
