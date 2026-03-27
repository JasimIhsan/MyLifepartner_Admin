import { SYSTEM_FEATURES } from "../../constants/SYSTEM_FEATURES";
import { Feature, IAdminFeatureService } from "../../interfaces/services/admin.feature.service.interface";

export class AdminFeatureService implements IAdminFeatureService {
   async getAllFeatures(): Promise<Feature[]> {
      return SYSTEM_FEATURES;
   }
}
