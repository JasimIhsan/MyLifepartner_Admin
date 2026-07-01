import prisma from "@/config/prisma";
import { Prisma, SubscriptionPlan } from "@prisma/client";
import { ISubscriptionRepository } from "../interfaces/repositories/subscription.repository.interface";

export class SubscriptionRepository implements ISubscriptionRepository {
   // ── Plans ──────────────────────────────────────────────────────────────────

   async createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] }> {
      return prisma.subscriptionPlan.create({
         data,
         include: { features: true },
      });
   }

   async getAllPlansWithFeatures(): Promise<(SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] })[]> {
      return prisma.subscriptionPlan.findMany({
         include: { features: { orderBy: { createdAt: "asc" } } },
         orderBy: { createdAt: "asc" },
      });
   }

   async getPlanById(id: number): Promise<(SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] }) | null> {
      return prisma.subscriptionPlan.findUnique({
         where: { id },
         include: { features: { orderBy: { createdAt: "asc" } } },
      });
   }

   async getPlanByName(name: string): Promise<SubscriptionPlan | null> {
      return prisma.subscriptionPlan.findUnique({ where: { name } });
   }

   async updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] }> {
      return prisma.subscriptionPlan.update({
         where: { id },
         data,
         include: { features: true },
      });
   }

   async untoggleMostPopularPlans(): Promise<Prisma.BatchPayload> {
      return prisma.subscriptionPlan.updateMany({
         where: { isMostPopular: true },
         data: { isMostPopular: false },
      });
   }

   async deletePlan(id: number): Promise<SubscriptionPlan> {
      // PlanFeature records are cascade-deleted by the DB relation
      return prisma.subscriptionPlan.delete({ where: { id } });
   }

   // ── Features ───────────────────────────────────────────────────────────────

   // ══════════════════════════════════════════════
   // Features (Plan mapping)
   // ══════════════════════════════════════════════

   async addFeaturesToPlan(planId: number, featureData: { featureKey: string; limit: string; description?: string }[]): Promise<import("@prisma/client").PlanFeature[]> {
      const data = featureData.map((f) => ({
         planId,
         featureKey: f.featureKey,
         limit: f.limit,
         description: f.description,
      }));

      // Create many
      await prisma.planFeature.createMany({
         data,
         skipDuplicates: true,
      });

      // Return newly created
      const featureKeys = featureData.map((f) => f.featureKey);
      return await prisma.planFeature.findMany({
         where: { planId, featureKey: { in: featureKeys } },
      });
   }

   async getPlanFeaturesByKeys(planId: number, featureKeys: string[]): Promise<import("@prisma/client").PlanFeature[]> {
      return await prisma.planFeature.findMany({
         where: { planId, featureKey: { in: featureKeys } },
      });
   }

   async getPlanFeatureById(id: number): Promise<import("@prisma/client").PlanFeature | null> {
      return await prisma.planFeature.findUnique({
         where: { id },
      });
   }

   async updatePlanFeature(id: number, data: { limit?: string; description?: string }): Promise<import("@prisma/client").PlanFeature> {
      return await prisma.planFeature.update({
         where: { id },
         data,
      });
   }

   async deletePlanFeature(id: number): Promise<import("@prisma/client").PlanFeature> {
      return await prisma.planFeature.delete({
         where: { id },
      });
   }

   // ── User Subscriptions ───────────────────────────────────────────────────

   async createUserSubscription(data: Prisma.UserSubscriptionCreateInput): Promise<import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }> {
      return prisma.userSubscription.create({
         data,
         include: {
            plan: { include: { features: true } },
         },
      }) as unknown as Promise<import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }>;
   }

   async findActiveSubscriptionByUserId(userId: number): Promise<(import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }) | null> {
      return prisma.userSubscription.findFirst({
         where: { userId, status: "ACTIVE" },
         include: { plan: { include: { features: true } } },
         orderBy: { createdAt: "desc" },
      }) as unknown as Promise<(import("@prisma/client").UserSubscription & { plan: import("@prisma/client").SubscriptionPlan & { features: import("@prisma/client").PlanFeature[] } }) | null>;
   }

   async deactivateUserSubscriptions(userId: number): Promise<Prisma.BatchPayload> {
      return prisma.userSubscription.updateMany({
         where: { userId, status: "ACTIVE" },
         data: { status: "EXPIRED" },
      });
   }

   async updateUserSubscription(id: number, data: Prisma.UserSubscriptionUpdateInput): Promise<any> {
      return prisma.userSubscription.update({
         where: { id },
         data,
         include: { plan: { include: { features: true } } },
      });
   }

   async findPlanByIdentifier(identifier: string): Promise<SubscriptionPlan | null> {
      return prisma.subscriptionPlan.findUnique({
         where: { identifier },
      });
   }

   async hasProcessedEvent(eventId: string): Promise<boolean> {
      const event = await prisma.processedRevenueCatEvent.findUnique({
         where: { id: eventId },
      });
      return !!event;
   }

   async markEventProcessed(eventId: string, type: string): Promise<void> {
      await prisma.processedRevenueCatEvent.create({
         data: { id: eventId, type },
      });
   }
}
