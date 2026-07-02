import { FeatureKey } from "../../enums/feature-key.enum";

export interface Feature {
   id: number;
   key: FeatureKey;
   name: string;
   boolean: boolean;
   description?: string | null;
}

export interface IAdminFeatureService {
   getAllFeatures(): Promise<Feature[]>;
}
