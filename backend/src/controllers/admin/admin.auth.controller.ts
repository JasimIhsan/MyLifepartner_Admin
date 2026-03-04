import { AdminLoginDto } from "@/dtos/admin.auth.dto";
import adminAuthService from "@/services/admin/admin.auth.service";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

class AdminAuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { username, password }: AdminLoginDto = req.body;
      const result = await adminAuthService.login(username, password);

      const isProduction = process.env.NODE_ENV === "production";

      // Set Access Token Cookie
      res.cookie("accessToken", result.accessToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 15 * 60 * 1000, // 15 minutes
      });

      // Set Refresh Token Cookie
      res.cookie("refreshToken", result.refreshToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user: result.user }, "Admin logged in successfully"));
   });

   refresh = asyncHandler(async (req: Request, res: Response) => {
      const incomingRefreshToken = req.cookies.refreshToken || req.body.refreshToken;

      if (!incomingRefreshToken) {
         return res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Refresh token is required"));
      }

      const { accessToken, refreshToken } = await adminAuthService.refreshTokens(incomingRefreshToken);

      const isProduction = process.env.NODE_ENV === "production";

      res.cookie("accessToken", accessToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 15 * 60 * 1000, // 15 minutes
      });

      res.cookie("refreshToken", refreshToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { success: true }, "Token refreshed successfully"));
   });

   logout = asyncHandler(async (req: Request, res: Response) => {
      const user = req.user;

      if (user && user.id) {
         await adminAuthService.logout(user.id);
      }

      const isProduction = process.env.NODE_ENV === "production";

      res.clearCookie("accessToken", {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
      });

      res.clearCookie("refreshToken", {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Admin logged out successfully"));
   });

   getMe = asyncHandler(async (req: Request, res: Response) => {
      const user = req.user;
      console.log(`👉 user : `, user);

      if (!user) {
         return res.status(HTTP_STATUS.UNAUTHORIZED).json(new ApiResponse(HTTP_STATUS.UNAUTHORIZED, null, "Unauthorized"));
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user }, "User fetched successfully"));
   });
}

export default new AdminAuthController();
