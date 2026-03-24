import { Feature, Prisma } from "@prisma/client";

export interface IFeatureRepository {
   createFeature(data: Prisma.FeatureCreateInput): Promise<Feature>;
   getAllFeatures(): Promise<Feature[]>;
   getFeatureById(id: number): Promise<Feature | null>;
   getFeatureByKey(key: string): Promise<Feature | null>;
   updateFeature(id: number, data: Prisma.FeatureUpdateInput): Promise<Feature>;
   deleteFeature(id: number): Promise<Feature>;
}
