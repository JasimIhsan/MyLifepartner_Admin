import { Feature } from "@prisma/client";
import { CreateFeatureInput, IAdminFeatureService, UpdateFeatureInput } from "../../interfaces/services/admin.feature.service.interface";
import { IFeatureRepository } from "../../interfaces/repositories/feature.repository.interface";
import { ApiError } from "../../utils/ApiError";

export class AdminFeatureService implements IAdminFeatureService {
    constructor(private featureRepository: IFeatureRepository) {}

    async createFeature(data: CreateFeatureInput): Promise<Feature> {
        const existing = await this.featureRepository.getFeatureByKey(data.key);
        if (existing) {
            throw new ApiError(409, `Feature with key '${data.key}' already exists`);
        }

        return await this.featureRepository.createFeature({
            key: data.key,
            name: data.name,
            description: data.description
        });
    }

    async getAllFeatures(): Promise<Feature[]> {
        return await this.featureRepository.getAllFeatures();
    }

    async getFeatureById(id: number): Promise<Feature> {
        const feature = await this.featureRepository.getFeatureById(id);
        if (!feature) {
            throw new ApiError(404, "Feature not found");
        }
        return feature;
    }

    async updateFeature(id: number, data: UpdateFeatureInput): Promise<Feature> {
        const feature = await this.featureRepository.getFeatureById(id);
        if (!feature) {
            throw new ApiError(404, "Feature not found");
        }

        return await this.featureRepository.updateFeature(id, data);
    }

    async deleteFeature(id: number): Promise<void> {
        const feature = await this.featureRepository.getFeatureById(id);
        if (!feature) {
            throw new ApiError(404, "Feature not found");
        }

        await this.featureRepository.deleteFeature(id);
    }
}
