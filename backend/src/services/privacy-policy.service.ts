import { CanViewOriginalImageParams, IPrivacyPolicyService } from "@/interfaces/services/privacy-policy.service.interface";

export class PrivacyPolicyService implements IPrivacyPolicyService {
   /**
    * Determines if the viewer is allowed to see the original, unblurred image of the target user.
    * 
    * Rules:
    * 1. If viewer is the target user, allow.
    * 2. If access has been explicitly approved, allow.
    * 3. If neither user has privacy enabled, allow.
    * 4. Otherwise, deny (return blurred image).
    * 
    * @param params Parameters containing viewer and target privacy states and access status.
    * @returns true if original image can be viewed, false otherwise.
    */
   public canViewOriginalImage(params: CanViewOriginalImageParams): boolean {
      if (params.viewerUserId === params.targetUserId) {
         return true;
      }
      
      if (params.hasApprovedAccess) {
         return true;
      }
      
      if (!params.viewerPrivacyEnabled && !params.targetPrivacyEnabled) {
         return true;
      }
      
      return false;
   }
}
