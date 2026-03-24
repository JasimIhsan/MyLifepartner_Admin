import prisma from "@/config/prisma";
import { IFeatureRepository } from "@/interfaces/repositories/feature.repository.interface";
import { Feature, Prisma, PrismaClient } from "@prisma/client";

export class FeatureRepository implements IFeatureRepository {
   private db: PrismaClient;

   constructor() {
      this.db = prisma;
   }

   async createFeature(data: Prisma.FeatureCreateInput): Promise<Feature> {
      return await this.db.feature.create({ data });
   }

   async getAllFeatures(): Promise<Feature[]> {
      return await this.db.feature.findMany({
         orderBy: {
            createdAt: "desc",
         },
      });
   }

   async getFeatureById(id: number): Promise<Feature | null> {
      return await this.db.feature.findUnique({
         where: { id },
      });
   }

   async getFeatureByKey(key: string): Promise<Feature | null> {
      return await this.db.feature.findUnique({
         where: { key },
      });
   }

   async updateFeature(id: number, data: Prisma.FeatureUpdateInput): Promise<Feature> {
      return await this.db.feature.update({
         where: { id },
         data,
      });
   }

   async deleteFeature(id: number): Promise<Feature> {
      return await this.db.feature.delete({
         where: { id },
      });
   }
}
