import prisma from "@/config/prisma";
import { PlanFeature, Prisma, SubscriptionPlan } from "@prisma/client";
import { ISubscriptionRepository, SubscriptionPlanWithFeatures } from "../interfaces/repositories/subscription.repository.interface";

export class SubscriptionRepository implements ISubscriptionRepository {
   // ── Plans ──────────────────────────────────────────────────────────────────

   async createPlan(data: Prisma.SubscriptionPlanCreateInput): Promise<SubscriptionPlan> {
      return prisma.subscriptionPlan.create({ data });
   }

   async getPlans(): Promise<SubscriptionPlanWithFeatures[]> {
      return prisma.subscriptionPlan.findMany({
         include: { features: { orderBy: { createdAt: "asc" } } },
         orderBy: { createdAt: "asc" },
      });
   }

   async getPlanById(id: number): Promise<SubscriptionPlanWithFeatures | null> {
      return prisma.subscriptionPlan.findUnique({
         where: { id },
         include: { features: { orderBy: { createdAt: "asc" } } },
      });
   }

   async getPlanByName(name: string): Promise<SubscriptionPlan | null> {
      return prisma.subscriptionPlan.findUnique({ where: { name } });
   }

   async updatePlan(id: number, data: Prisma.SubscriptionPlanUpdateInput): Promise<SubscriptionPlan> {
      return prisma.subscriptionPlan.update({ where: { id }, data });
   }

   async deletePlan(id: number): Promise<SubscriptionPlan> {
      // PlanFeature records are cascade-deleted by the DB relation
      return prisma.subscriptionPlan.delete({ where: { id } });
   }

   // ── Features ───────────────────────────────────────────────────────────────

   async addFeatures(planId: number, features: { key: string; value: string }[]): Promise<PlanFeature[]> {
      // Use createMany + then re-fetch so we always return typed PlanFeature[]
      await prisma.planFeature.createMany({
         data: features.map((f) => ({ planId, key: f.key, value: f.value })),
         skipDuplicates: false, // let the DB unique constraint surface a conflict
      });

      // Return the newly created features for this plan
      return prisma.planFeature.findMany({
         where: { planId, key: { in: features.map((f) => f.key) } },
         orderBy: { createdAt: "asc" },
      });
   }

   async getFeatureById(id: number): Promise<PlanFeature | null> {
      return prisma.planFeature.findUnique({ where: { id } });
   }

   async updateFeature(id: number, value: string): Promise<PlanFeature> {
      return prisma.planFeature.update({ where: { id }, data: { value } });
   }

   async deleteFeature(id: number): Promise<PlanFeature> {
      return prisma.planFeature.delete({ where: { id } });
   }
}
