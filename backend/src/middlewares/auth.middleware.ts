import { jwtService, userService } from "@/composer/composer";
import { ApiError } from "@/utils/ApiError";
import { asyncHandler } from "@/utils/asyncHandler";
import { NextFunction, Request, Response } from "express";

export const verifyJWT = asyncHandler(async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
   const token = getAuthToken(req);

   if (!token) {
      throw new ApiError(401, "Unauthorized request");
   }

   try {
      const decoded = jwtService.verifyAccess(token);

      await userService.validateUserAccountStatus(decoded.id);

      req.user = decoded;
      next();
   } catch (error: any) {
      if (error instanceof ApiError) throw error;
      throw new ApiError(401, "Invalid access token");
   }
});

/**
 * Gets auth token from cookies or authorization header.
 *
 * @param req - Express request.
 * @returns Auth token, or undefined if not found.
 */
const getAuthToken = (req: Request): string | undefined => {
   const authHeader = req.header("Authorization");

   if (authHeader?.startsWith("Bearer ")) {
      return authHeader.split(" ")[1];
   }

   const cookieToken = req.cookies?.accessToken;

   if (cookieToken) {
      return cookieToken;
   }

   return undefined;
};
