import { ZegoService } from "@/services/zego.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class ZegoController {
   constructor(private readonly zegoService: ZegoService) {}

   /**
    * @route GET /api/v1/user/zego/token
    * @purpose Generates a ZEGOCLOUD token for the authenticated user.
    */
   public getToken = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const token = this.zegoService.generateToken(String(userId));

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { token, userId: String(userId) }, "ZEGO token generated successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: Request): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }
}
