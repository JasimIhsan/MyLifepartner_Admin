import { S3Service } from "@/services/s3.service";
import { ProfileService } from "@/services/user/user.profile.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Response } from "express";

export class ProfileImageController {
   constructor(
      private profileService: ProfileService,
      private s3Service: S3Service
   ) {}

   public uploadImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      if (!userId) throw new ApiError(401, "Unauthorized");

      if (!req.file) {
         throw new ApiError(400, "No image file provided");
      }

      // 1. Upload to S3
      const s3Url = await this.s3Service.uploadToS3(req.file, `${userId}/profile`);

      // 2. Save to DB
      try {
         const newImage = await this.profileService.uploadUserImage(Number(userId), s3Url);

         // Generate presigned URL for immediate response
         newImage.imageUrl = await this.s3Service.getPresignedUrl(newImage.imageUrl);

         res.status(201).json(new ApiResponse(201, newImage, "Image uploaded successfully"));
      } catch (error) {
         // Rollback S3 upload if DB fails
         await this.s3Service.deleteFromS3(s3Url);
         throw error;
      }
   });

   public removeImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      const imageId = req.params.imageId;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const images = await this.profileService.getUserImages(Number(userId));
      const imageToDelete = images.find((img) => img.id === Number(imageId));

      if (!imageToDelete) {
         throw new ApiError(404, "Image not found");
      }

      // Delete from S3
      if (imageToDelete.imageUrl) {
         await this.s3Service.deleteFromS3(imageToDelete.imageUrl);
      }

      // Delete from DB
      await this.profileService.deleteUserImage(Number(userId), Number(imageId));

      res.status(200).json(new ApiResponse(200, null, "Image removed successfully"));
   });

   public setPrimaryImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      const imageId = req.params.imageId;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const updatedImage = await this.profileService.setPrimaryImage(Number(userId), Number(imageId));

      res.status(200).json(new ApiResponse(200, updatedImage, "Primary image set successfully"));
   });

   public getImages = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const images = await this.profileService.getUserImages(Number(userId));

      // Generate presigned URLs for each image
      const imagesWithPresignedUrls = await Promise.all(
         images.map(async (img) => {
            if (img.imageUrl) {
               img.imageUrl = await this.s3Service.getPresignedUrl(img.imageUrl);
            }
            return img;
         })
      );

      console.log("👉 images with presigned urls: ", imagesWithPresignedUrls);
      res.status(200).json(new ApiResponse(200, imagesWithPresignedUrls, "User images fetched successfully"));
   });

   public completeImageUpload = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const result = await this.profileService.completeImageUpload(Number(userId));

      res.status(200).json(new ApiResponse(200, result, "Image upload phase completed successfully"));
   });

   public uploadSelfie = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId || req.user.id;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const files = req.files as { [fieldname: string]: Express.Multer.File[] } | undefined;
      if (!files || !files.frontImage || !files.leftImage || !files.rightImage) {
         throw new ApiError(400, "All three selfie images (front, left, right) are required");
      }

      const frontFile = files.frontImage[0];
      const leftFile = files.leftImage[0];
      const rightFile = files.rightImage[0];

      // 1. Upload to S3
      const [frontS3Url, leftS3Url, rightS3Url] = await Promise.all([
         this.s3Service.uploadToS3(frontFile, `${userId}/selfie_front`),
         this.s3Service.uploadToS3(leftFile, `${userId}/selfie_left`),
         this.s3Service.uploadToS3(rightFile, `${userId}/selfie_right`),
      ]);

      // 2. Save to DB
      try {
         const { user, oldSelfieUrls } = await this.profileService.uploadSelfie(Number(userId), frontS3Url, leftS3Url, rightS3Url);

         // Delete old selfies from S3 if they exist
         const deletePromises: Promise<void>[] = [];
         if (oldSelfieUrls.front) deletePromises.push(this.s3Service.deleteFromS3(oldSelfieUrls.front));
         if (oldSelfieUrls.left) deletePromises.push(this.s3Service.deleteFromS3(oldSelfieUrls.left));
         if (oldSelfieUrls.right) deletePromises.push(this.s3Service.deleteFromS3(oldSelfieUrls.right));
         await Promise.all(deletePromises);

         res.status(201).json(new ApiResponse(201, { selfieStatus: user.selfieStatus }, "Selfies uploaded successfully. Awaiting review."));
      } catch (error) {
         // Rollback S3 uploads if DB fails
         await Promise.all([
            this.s3Service.deleteFromS3(frontS3Url),
            this.s3Service.deleteFromS3(leftS3Url),
            this.s3Service.deleteFromS3(rightS3Url),
         ]);
         throw error;
      }
   });
}
