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

      if (!req.file) {
         throw new ApiError(400, "No selfie image file provided");
      }

      // 1. Upload to S3
      const s3Url = await this.s3Service.uploadToS3(req.file, `${userId}/selfie`);

      // 2. Save to DB
      try {
         const { user, oldSelfieUrl } = await this.profileService.uploadSelfie(Number(userId), s3Url);

         // Delete old selfie from S3 if it exists
         if (oldSelfieUrl) {
            await this.s3Service.deleteFromS3(oldSelfieUrl);
         }

         res.status(201).json(new ApiResponse(201, { selfieStatus: user.selfieStatus }, "Selfie uploaded successfully. Awaiting review."));
      } catch (error) {
         // Rollback S3 upload if DB fails
         await this.s3Service.deleteFromS3(s3Url);
         throw error;
      }
   });
}
