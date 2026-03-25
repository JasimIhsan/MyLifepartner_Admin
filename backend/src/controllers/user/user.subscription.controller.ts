import { Request, Response } from "express";
import { asyncHandler } from "@/utils/asyncHandler";
import { ApiResponse } from "@/utils/ApiResponse";
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
}
