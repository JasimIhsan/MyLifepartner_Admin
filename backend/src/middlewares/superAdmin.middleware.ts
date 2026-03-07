import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { NextFunction, Response } from "express";

export const isSuperAdmin = asyncHandler(async (req: AuthRequest, res: Response, next: NextFunction) => {
   if (!req.user || req.user.role !== "SUPER_ADMIN") {
      throw new ApiError(HTTP_STATUS.FORBIDDEN, "Access denied. Super Admin role required.");
   }
   next();
});
