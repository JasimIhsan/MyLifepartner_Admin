import { IOAuthService } from "@/interfaces/services/user.oauth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class OAuthController {
   constructor(private readonly oauthService: IOAuthService) {}

   /**
    * @route POST /api/v1/user/oauth/google
    * @purpose Authenticate user with Google ID Token.
    */
   public googleSignIn = asyncHandler(async (req: Request, res: Response) => {
      const idToken = this.getRequiredString(req.body.idToken, "ID token is required");

      const result = await this.oauthService.googleSignIn(idToken);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Google sign-in successful"));
   });

   /**
    * Extracts and validates a required string value.
    */
   private getRequiredString(value: unknown, errorMessage: string): string {
      if (typeof value !== "string" || value.trim().length === 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return value.trim();
   }
}
