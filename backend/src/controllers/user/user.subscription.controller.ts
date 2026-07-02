import { Request, Response } from "express";
import { asyncHandler } from "@/utils/asyncHandler";
import { ApiResponse } from "@/utils/ApiResponse";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";

export class UserSubscriptionController {

   constructor(
      private userSubscriptionService: IUserSubscriptionService,
      private userFeatureService: IUserFeatureService
   ) {}

   /** GET /user/subscriptions/plans */
   getPlans = asyncHandler(async (req: Request, res: Response) => {
      const plans = await this.userSubscriptionService.getPlans();
      res.status(200).json(new ApiResponse(200, plans, "Subscription plans retrieved successfully"));
   });

   /** GET /user/subscriptions/my-subscription */
   getMySubscription = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id; // assuming auth middleware sets req.user
      const subscription = await this.userSubscriptionService.getMySubscription(userId);
      res.status(200).json(new ApiResponse(200, subscription, "Current subscription retrieved"));
   });

   /** GET /user/subscriptions/features */
   getUserFeatures = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id; // assuming auth middleware sets req.user
      const features = await this.userSubscriptionService.getUserFeatures(userId);
      res.status(200).json(new ApiResponse(200, features, "Current features retrieved"));
   });

   /** POST /user/subscriptions/subscribe */
   subscribe = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id; // assuming auth middleware sets req.user
      const { planId } = req.body;

      if (!planId) {
         res.status(400).json(new ApiResponse(400, null, "planId is required"));
         return;
      }

      const subscription = await this.userSubscriptionService.subscribe(userId, parseInt(planId));
      res.status(201).json(new ApiResponse(201, subscription, "Subscribed successfully"));
   });

     /** POST /user/subscriptions/check-call-access */
   checkCallAccess = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id;
      const { type, consumeSeconds, targetUserId } = req.body; // "audio" | "video", optional consumeSeconds, optional targetUserId
      
      const targetUserIdParsed = targetUserId ? parseInt(targetUserId) : undefined;

      await this.userFeatureService.checkCallAccess(userId, type, consumeSeconds, targetUserIdParsed);
      
      res.status(200).json(new ApiResponse(200, null, "Call allowed"));
   });

   /** POST /user/subscriptions/sync */
   sync = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id;
      const subscription = await this.userSubscriptionService.syncSubscription(userId);
      res.status(200).json(new ApiResponse(200, subscription, "Subscription synced successfully"));
   });

   /** POST /user/subscriptions/webhook */
   webhook = asyncHandler(async (req: Request, res: Response) => {
      const signatureHeader = req.headers["authorization"] as string || "";
      await this.userSubscriptionService.handleWebhook(req.body, signatureHeader);
      res.status(200).json(new ApiResponse(200, null, "Webhook handled successfully"));
   });
}
