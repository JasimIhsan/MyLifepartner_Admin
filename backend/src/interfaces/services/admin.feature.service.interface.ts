import { FeatureKey } from "../../enums/feature-key.enum";

export interface Feature {
   id: number;
   key: FeatureKey;
   name: string;
   description?: string | null;
}

export interface IAdminFeatureService {
   getAllFeatures(): Promise<Feature[]>;
}
