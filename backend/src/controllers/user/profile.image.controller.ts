import { S3Service } from "@/services/s3.service";
import { ProfileService } from "@/services/user/user.profile.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

export class ProfileImageController {
   constructor(
      private readonly profileService: ProfileService
   ) {}

   /**
    * @route POST /api/v1/user/profile/upload-image/:userId
    * @purpose Uploads a profile image for the authenticated user.
    */
   public uploadImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      if (!req.file) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "No image file provided");
      }

      const newImage = await this.profileService.uploadUserImage(userId, req.file);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "UPLOAD_PROFILE_IMAGE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User uploaded a new profile image`,
         newValue: newImage,
         entityType: "UserImage",
         entityId: newImage.id.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, newImage, "Image uploaded successfully"));
   });

   /**
    * @route PUT /api/v1/user/profile/replace-image/:userId/:imageId
    * @purpose Replaces a profile image for the authenticated user.
    */
   public replaceImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);
      const imageId = Number(req.params.imageId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      if (!Number.isInteger(imageId) || imageId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      if (!req.file) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "No image file provided");
      }

      const updatedImage = await this.profileService.replaceUserImage(userId, imageId, req.file);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "REPLACE_PROFILE_IMAGE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User replaced profile image ID: ${imageId}`,
         newValue: updatedImage,
         entityType: "UserImage",
         entityId: imageId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedImage, "Image replaced successfully"));
   });

   /**
    * @route PATCH /api/v1/user/profile/set-primary/:userId/:imageId
    * @purpose Sets a profile image as the primary image.
    */
   public setPrimaryImage = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);
      const imageId = Number(req.params.imageId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      if (!Number.isInteger(imageId) || imageId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid image ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const updatedImage = await this.profileService.setPrimaryImage(userId, imageId);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "SET_PRIMARY_PROFILE_IMAGE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User set image ID: ${imageId} as primary`,
         newValue: updatedImage,
         entityType: "UserImage",
         entityId: imageId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedImage, "Primary image set successfully"));
   });

   /**
    * @route GET /api/v1/user/profile/images/:userId
    * @purpose Fetches profile images for the authenticated user.
    */
   public getImages = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const images = await this.profileService.getUserImages(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, images, "User images fetched successfully"));
   });

   /**
    * @route POST /api/v1/user/profile/complete-image-upload/:userId
    * @purpose Marks profile image upload step as complete.
    */
   public completeImageUpload = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.completeImageUpload(userId);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "COMPLETE_IMAGE_UPLOAD",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User completed image upload phase`,
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Image upload phase completed successfully"));
   });

   /**
    * @route POST /api/v1/user/profile/upload-selfie/:userId
    * @purpose Uploads selfie images for profile verification.
    */
   public uploadSelfie = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const files = req.files as { [fieldname: string]: Express.Multer.File[] } | undefined;

      if (!files?.frontImage?.[0] || !files?.leftImage?.[0] || !files?.rightImage?.[0]) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "All three selfie images (front, left, right) are required");
      }

      const latitude = req.body.latitude ? Number(req.body.latitude) : undefined;
      const longitude = req.body.longitude ? Number(req.body.longitude) : undefined;

      if (latitude !== undefined && Number.isNaN(latitude)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid latitude");
      }

      if (longitude !== undefined && Number.isNaN(longitude)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid longitude");
      }

      const frontFile = files.frontImage[0];
      const leftFile = files.leftImage[0];
      const rightFile = files.rightImage[0];

      const { user } = await this.profileService.uploadSelfie(userId, frontFile, leftFile, rightFile, latitude, longitude);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "UPLOAD_SELFIE_VERIFICATION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User uploaded selfies for verification`,
         newValue: { selfieStatus: user.selfieStatus, profileStatus: user.profileStatus },
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, { selfieStatus: user.selfieStatus, profileStatus: user.profileStatus }, "Selfies uploaded successfully. Awaiting review."));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Ensures authenticated user owns the requested resource.
    */
   private ensureUserOwnsResource(resourceUserId: number, authUserId: number): void {
      if (resourceUserId !== authUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Forbidden");
      }
   }
}
