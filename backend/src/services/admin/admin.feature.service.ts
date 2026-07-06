import { SYSTEM_FEATURES } from "@/constants/SYSTEM_FEATURES";
import { Feature, IAdminFeatureService } from "@/interfaces/services/admin.feature.service.interface";

export class AdminFeatureService implements IAdminFeatureService {
   /**
    * Gets all system features.
    *
    * @returns System features.
    */
   async getAllFeatures(): Promise<Feature[]> {
      return SYSTEM_FEATURES;
   }
}
