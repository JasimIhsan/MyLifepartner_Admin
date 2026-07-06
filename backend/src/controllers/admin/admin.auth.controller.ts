import { AdminLoginDto } from "@/dtos/admin.auth.dto";
import { IAdminAuthService } from "@/interfaces/services/admin.auth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class AdminAuthController {
   constructor(private readonly adminAuthService: IAdminAuthService) {}

   /**
    * @route POST /api/v1/admin/auth/login
    * @purpose Logs in an admin and sets auth cookies.
    */
   public login = asyncHandler(async (req: Request, res: Response) => {
      const { username, password }: AdminLoginDto = req.body;

      if (!username || !password) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      const result = await this.adminAuthService.login(username, password);

      this.setAuthCookies(res, result.accessToken, result.refreshToken);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user: result.user }, "Admin logged in successfully"));
   });

   /**
    * @route POST /api/v1/admin/auth/refresh
    * @purpose Refreshes admin access and refresh tokens.
    */
   public refresh = asyncHandler(async (req: Request, res: Response) => {
      const incomingRefreshToken = req.cookies?.refreshToken || req.body.refreshToken;

      if (!incomingRefreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      const { accessToken, refreshToken } = await this.adminAuthService.refreshTokens(incomingRefreshToken);

      this.setAuthCookies(res, accessToken, refreshToken);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { success: true }, "Token refreshed successfully"));
   });

   /**
    * @route POST /api/v1/admin/auth/logout
    * @purpose Logs out the authenticated admin and clears auth cookies.
    */
   public logout = asyncHandler(async (req: Request, res: Response) => {
      const adminId = req.user?.id;

      if (adminId) {
         await this.adminAuthService.logout(adminId);
      }

      this.clearAuthCookies(res);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Admin logged out successfully"));
   });

   /**
    * @route GET /api/v1/admin/auth/me
    * @purpose Fetches the authenticated admin profile.
    */
   public getMe = asyncHandler(async (req: Request, res: Response) => {
      const user = req.user;

      if (!user) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user }, "Admin fetched successfully"));
   });

   /**
    * Sets access and refresh token cookies.
    */
   private setAuthCookies(res: Response, accessToken: string, refreshToken: string): void {
      const isProduction = process.env.NODE_ENV === "production";

      res.cookie("accessToken", accessToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 15 * 60 * 1000,
      });

      res.cookie("refreshToken", refreshToken, {
         httpOnly: true,
         secure: isProduction,
         sameSite: isProduction ? "none" : "lax",
         maxAge: 7 * 24 * 60 * 60 * 1000,
      });
   }

   /**
    * Clears access and refresh token cookies.
    */
   private clearAuthCookies(res: Response): void {
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
   }
}
