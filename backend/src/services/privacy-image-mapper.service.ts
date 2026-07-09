import { IPrivacyImageMapperService, MapImagesParams, PrivacyImageDto } from "@/interfaces/services/privacy-image-mapper.service.interface";
import { IPrivacyPolicyService } from "@/interfaces/services/privacy-policy.service.interface";
import { IS3Service } from "@/interfaces/services/s3.service.interface";

export class PrivacyImageMapperService implements IPrivacyImageMapperService {
   constructor(
      private readonly privacyPolicyService: IPrivacyPolicyService,
      private readonly s3Service: IS3Service
   ) {}

   /**
    * Maps an array of target images to privacy-safe image DTOs.
    * When privacy blocks original access: primary shows blurred, non-primary shows null.
    *
    * @param params Parameters containing viewer and target privacy states and the images to map.
    * @returns Array of PrivacyImageDto
    */
   public async mapImages(params: MapImagesParams): Promise<PrivacyImageDto[]> {
      const canViewOriginal = this.privacyPolicyService.canViewOriginalImage({
         viewerUserId: params.viewerUserId,
         viewerPrivacyEnabled: params.viewerPrivacyEnabled,
         targetUserId: params.targetUserId,
         targetPrivacyEnabled: params.targetPrivacyEnabled,
         hasApprovedAccess: params.hasApprovedAccess,
      });

      if (canViewOriginal) {
         return Promise.all(
            params.targetImages.map(async (image) => {
               const signedUrl = await this.s3Service.getPresignedUrl(image.imageUrl);
               return {
                  id: image.id,
                  imageUrl: signedUrl,
                  isPrimary: image.isPrimary,
                  isBlurred: false,
               };
            })
         );
      }

      // Privacy blocks original — only return a single blurred primary image
      if (params.targetBlurredImageUrl) {
         const primaryImage = params.targetImages.find((img) => img.isPrimary);
         const signedUrl = await this.s3Service.getPresignedUrl(params.targetBlurredImageUrl);
         return [
            {
               id: primaryImage?.id ?? 0,
               imageUrl: signedUrl,
               isPrimary: true,
               isBlurred: true,
            },
         ];
      }

      return [];
   }
}
