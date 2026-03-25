export interface Feature {
   id: number;
   key: string;
   name: string;
   description?: string | null;
}

export interface IAdminFeatureService {
   getAllFeatures(): Promise<Feature[]>;
}
