import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";

export class PrivacyController {
   constructor(private readonly profileService: IProfileService) {}

   /**
    * @route PATCH /api/v1/user/profile/privacy or /privacy/:userId
    * @purpose Updates privacy settings for the user's profile.
    */
   public updatePrivacySettings = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = req.params.userId ? Number(req.params.userId) : authUserId;

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const { privacyEnabled } = req.body;

      if (typeof privacyEnabled !== "boolean") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "privacyEnabled must be a boolean");
      }

      const result = await this.profileService.updatePrivacySettings(userId, privacyEnabled);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Privacy settings updated successfully"));
   });

   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);
      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }
      return userId;
   }

   private ensureUserOwnsResource(resourceUserId: number, authUserId: number): void {
      if (resourceUserId !== authUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Forbidden");
      }
   }
}
