import { jwtService } from "@/composer/composer";
import { ApiResponse } from "@/utils/ApiResponse";
import { HTTP_STATUS } from "@/utils/constants";
import { NextFunction, Request, Response } from "express";

const ADMIN_ROLES = ["ADMIN", "SUPER_ADMIN"] as const;

export const authenticateAdmin = (req: Request, res: Response, next: NextFunction): void => {
   const token = getAuthToken(req);

   if (!token) {
      res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Authentication token missing"));
      return;
   }

   try {
      const decoded = jwtService.verifyAccess(token);

      if (!ADMIN_ROLES.includes(decoded.role as (typeof ADMIN_ROLES)[number])) {
         res.status(HTTP_STATUS.FORBIDDEN).json(new ApiResponse(HTTP_STATUS.FORBIDDEN, null, "Access denied. Admins only."));
         return;
      }

      req.user = decoded;
      next();
   } catch {
      res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Invalid or expired token"));
   }
};

/**
 * Gets auth token from cookies or authorization header.
 *
 * @param req - Express request.
 * @returns Auth token, or undefined if not found.
 */
const getAuthToken = (req: Request): string | undefined => {
   const authHeader = req.headers.authorization;

   if (authHeader?.startsWith("Bearer ")) {
      return authHeader.split(" ")[1];
   }

   const cookieToken = req.cookies?.accessToken;

   if (cookieToken) {
      return cookieToken;
   }

   return undefined;
};
