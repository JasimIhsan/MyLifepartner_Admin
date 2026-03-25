import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import prisma from "@/config/prisma";
import { SubscriptionPlan, UserSubscription } from "@prisma/client";
import { ApiError } from "@/utils/ApiError";

export class UserSubscriptionService implements IUserSubscriptionService {
   async getPlans(): Promise<SubscriptionPlan[]> {
      // Find all active plans, including features
      return await prisma.subscriptionPlan.findMany({
         where: { isActive: true },
         include: { features: { include: { feature: true } } },
         orderBy: { price: "asc" },
      });
   }

   async getMySubscription(userId: number): Promise<UserSubscription | null> {
      return await prisma.userSubscription.findFirst({
         where: { userId, status: "ACTIVE" },
         include: { plan: { include: { features: { include: { feature: true } } } } },
         orderBy: { createdAt: "desc" },
      });
   }

   async subscribe(userId: number, planId: number): Promise<UserSubscription> {
      const plan = await prisma.subscriptionPlan.findUnique({
         where: { id: planId },
      });

      if (!plan) {
         throw new ApiError(404, "Subscription plan not found");
      }

      if (!plan.isActive) {
         throw new ApiError(400, "This subscription plan is no longer active");
      }

      // Deactivate any existing active subscriptions for this user
      await prisma.userSubscription.updateMany({
         where: { userId, status: "ACTIVE" },
         data: { status: "EXPIRED" },
      });

      // Calculate end date based on durationDays
      const startDate = new Date();
      const endDate = new Date();
      endDate.setDate(startDate.getDate() + plan.durationDays);

      const userSubscription = await prisma.userSubscription.create({
         data: {
            userId,
            planId,
            status: "ACTIVE",
            startDate,
            endDate,
         },
         include: {
            plan: { include: { features: { include: { feature: true } } } },
         },
      });

      return userSubscription;
   }
}
