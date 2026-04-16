import { Request, Response } from "express";
import { asyncHandler } from "@/utils/asyncHandler";
import { ApiResponse } from "@/utils/ApiResponse";
import { ApiError } from "@/utils/ApiError";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";

export class UserSubscriptionController {
   constructor(private userSubscriptionService: IUserSubscriptionService) {}

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
      const { type } = req.body; // "audio" | "video"
      
      const features = await this.userSubscriptionService.getUserFeatures(userId);
      if (!features) {
         throw new ApiError(402, "Call feature not available in your plan.");
      }

      if (type === 'video') {
         if (!features.canVideoCall) throw new ApiError(402, "Video call not available in your plan.");
         if (features.maxVideoCallMinutes > 0 && features.videoCallMinutes >= features.maxVideoCallMinutes) {
            throw new ApiError(402, "Video call limit exhausted.");
         }
      } else {
         if (!features.canAudioCall) throw new ApiError(402, "Audio call not available in your plan.");
         if (features.maxAudioCallMinutes > 0 && features.audioCallMinutes >= features.maxAudioCallMinutes) {
            throw new ApiError(402, "Audio call limit exhausted.");
         }
      }
      
      res.status(200).json(new ApiResponse(200, null, "Call allowed"));
   });
}
