import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import fs from "fs";
import path from "path";

export class AuthController {
   constructor(
      private authService: IUserAuthService,
      private userService: IUserService
   ) {}

   initiateAuth = asyncHandler(async (req: Request, res: Response) => {
      const { email, purpose = "auth" } = req.body;
      const ip = req.ip || "";
      const result = await this.authService.initiateAuth(email, ip, purpose);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Auth initiated"));
   });

   verifyOtp = asyncHandler(async (req: Request, res: Response) => {
      const { email, otp, purpose = "auth" } = req.body;
      const result = await this.authService.verifyOtp(email, otp, purpose);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "OTP verified"));
   });

   login = asyncHandler(async (req: Request, res: Response) => {
      const { email, password } = req.body;
      const result = await this.authService.login(email, password);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User login success"));
   });

   register = asyncHandler(async (req: Request, res: Response) => {
      const { email, password } = req.body;
      const result = await this.authService.register(email, password);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User registered successfully"));
   });

   forgotPassword = asyncHandler(async (req: Request, res: Response) => {
      const { email, password } = req.body;
      const result = await this.authService.forgotPassword(email, password);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, result.message));
   });

   sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { email, purpose = "auth" } = req.body;
      const result = await this.authService.sendOtp(email, req.ip || "", purpose);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp sent successfully"));
   });

   resendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { email, purpose = "auth" } = req.body;
      const result = await this.authService.resendOtp(email, req.ip || "", purpose);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp resent successfully"));
   });


   refreshToken = asyncHandler(async (req: Request, res: Response) => {
      const { refreshToken } = req.body;
      const result = await this.authService.refreshToken(refreshToken);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Token refreshed successfully"));
   });

   me = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.user?.id;
      if (!userId) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      const status = await this.userService.getOnboardingStatus(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, status, "User status fetched successfully"));
   });


}
