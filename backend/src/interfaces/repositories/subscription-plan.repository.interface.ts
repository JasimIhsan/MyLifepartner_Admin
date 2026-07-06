import { PlanFeature, Prisma, SubscriptionPlan } from "@prisma/client";

export type PlanWithFeatures = SubscriptionPlan & { features: PlanFeature[] };

export interface ISubscriptionPlanRepository {
   createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<PlanWithFeatures>;
   getAllPlansWithFeatures(): Promise<PlanWithFeatures[]>;
   getPlanById(id: number): Promise<PlanWithFeatures | null>;
   getPlanByName(name: string): Promise<PlanWithFeatures | null>;
   findPlanByIdentifier(identifier: string): Promise<PlanWithFeatures | null>;
   updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<PlanWithFeatures>;
   untoggleMostPopularPlans(): Promise<Prisma.BatchPayload>;
   deletePlan(id: number): Promise<SubscriptionPlan>;
}
