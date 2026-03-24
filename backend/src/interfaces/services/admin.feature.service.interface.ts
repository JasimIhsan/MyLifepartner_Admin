import { Feature } from "@prisma/client";

export interface CreateFeatureInput {
   key: string;
   name: string;
   description?: string;
}

export interface UpdateFeatureInput {
   name?: string;
   description?: string;
}

export interface IAdminFeatureService {
   createFeature(data: CreateFeatureInput): Promise<Feature>;
   getAllFeatures(): Promise<Feature[]>;
   getFeatureById(id: number): Promise<Feature>;
   updateFeature(id: number, data: UpdateFeatureInput): Promise<Feature>;
   deleteFeature(id: number): Promise<void>;
}
