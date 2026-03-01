import { ApiResponse } from "@/utils/ApiResponse";
import { HTTP_STATUS } from "@/utils/constants";
import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";

export const authenticateAdmin = (req: Request, res: Response, next: NextFunction) => {
   const token = req.cookies?.accessToken || req.headers.authorization?.split(" ")[1];

   if (!token) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Authentication token missing"));
   }

   try {
      const decoded: any = jwt.verify(token, process.env.JWT_SECRET || "default_secret");

      if (decoded.role !== "ADMIN") {
         return res.status(HTTP_STATUS.FORBIDDEN).json(new ApiResponse(HTTP_STATUS.FORBIDDEN, null, "Access denied. Admins only."));
      }

      (req as any).user = decoded;
      next();
   } catch (error) {
      return res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Invalid or expired token"));
   }
};
