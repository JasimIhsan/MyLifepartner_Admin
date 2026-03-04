import { UserJwtPayload } from "@/types/express";
import { ApiError } from "@/utils/ApiError";
import { asyncHandler } from "@/utils/asyncHandler";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

export const verifyJWT = asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
   const token = req.cookies?.accessToken || req.header("Authorization")?.replace("Bearer ", "");

   console.log(`👉 token : `, token);

   if (!token) {
      throw new ApiError(401, "Unauthorized request");
   }

   try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET || "default_secret") as UserJwtPayload;
      console.log(`👉 decoded : `, decoded);
      req.user = decoded; // Attach user payload (id, mobileNumber) to req
      next();
   } catch (error) {
      throw new ApiError(401, "Invalid access token");
   }
});
