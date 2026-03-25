import { SubscriptionPlan, UserSubscription } from "@prisma/client";

export interface IUserSubscriptionService {
   getPlans(): Promise<SubscriptionPlan[]>;
   getMySubscription(userId: number): Promise<UserSubscription | null>;
   subscribe(userId: number, planId: number): Promise<UserSubscription>;
}
