import prisma from "@/config/prisma";
import { Prisma, SubscriptionPlan } from "@prisma/client";
import { ISubscriptionRepository } from "../interfaces/repositories/subscription.repository.interface";

export class SubscriptionRepository implements ISubscriptionRepository {
   // ── Plans ──────────────────────────────────────────────────────────────────

   async createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<any> {
      return prisma.subscriptionPlan.create({
         data,
         include: { features: { include: { feature: true } } },
      });
   }

   async getAllPlansWithFeatures(): Promise<any[]> {
      return prisma.subscriptionPlan.findMany({
         include: { features: { include: { feature: true }, orderBy: { createdAt: "asc" } } },
         orderBy: { createdAt: "asc" },
      });
   }

   async getPlanById(id: number): Promise<any | null> {
      return prisma.subscriptionPlan.findUnique({
         where: { id },
         include: { features: { include: { feature: true }, orderBy: { createdAt: "asc" } } },
      });
   }

   async getPlanByName(name: string): Promise<SubscriptionPlan | null> {
      return prisma.subscriptionPlan.findUnique({ where: { name } });
   }

   async updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<any> {
      return prisma.subscriptionPlan.update({
         where: { id },
         data,
         include: { features: { include: { feature: true } } },
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

   async addFeaturesToPlan(planId: number, featureData: { featureId: number; limit: string }[]): Promise<any[]> {
      const data = featureData.map((f) => ({
         planId,
         featureId: f.featureId,
         limit: f.limit,
      }));

      // Create many
      await prisma.planFeature.createMany({
         data,
         skipDuplicates: true,
      });

      // Return newly created
      const featureIds = featureData.map((f) => f.featureId);
      return await prisma.planFeature.findMany({
         where: { planId, featureId: { in: featureIds } },
         include: { feature: true },
      });
   }

   async getPlanFeaturesByKeys(planId: number, featureIds: number[]): Promise<any[]> {
      return await prisma.planFeature.findMany({
         where: { planId, featureId: { in: featureIds } },
         include: { feature: true },
      });
   }

   async getPlanFeatureById(id: number): Promise<any | null> {
      return await prisma.planFeature.findUnique({
         where: { id },
         include: { feature: true },
      });
   }

   async updatePlanFeature(id: number, limit: string): Promise<any> {
      return await prisma.planFeature.update({
         where: { id },
         data: { limit },
         include: { feature: true },
      });
   }

   async deletePlanFeature(id: number): Promise<any> {
      return await prisma.planFeature.delete({
         where: { id },
      });
   }
}
