import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiResponse } from "@/utils/ApiResponse";
import { ApiError } from "@/utils/ApiError";
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
      const { email } = req.body;
      const ip = req.ip || "";
      const result = await this.authService.initiateAuth(email, ip);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Auth initiated"));
   });

   verifyOtp = asyncHandler(async (req: Request, res: Response) => {
      const { email, otp } = req.body;
      const result = await this.authService.verifyOtp(email, otp);
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
      const { email } = req.body;
      const result = await this.authService.sendOtp(email, req.ip || "");
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp sent successfully"));
   });

   resendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { email } = req.body;
      const result = await this.authService.resendOtp(email, req.ip || "");
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Otp resent successfully"));
   });

   detectCountry = asyncHandler(async (req: Request, res: Response) => {
      const countryCodeHeader = (req.headers["cf-ipcountry"] || req.headers["x-vercel-ip-country"]) as string;
      const ip = req.ip;

      const result = await this.authService.detectCountryAsync(ip, countryCodeHeader);

      return res.status(HTTP_STATUS.OK).json(
         new ApiResponse(
            HTTP_STATUS.OK,
            {
               country: result.country,
               countryCode: result.countryCode,
               callingCode: result.callingCode,
            },
            result.message
         )
      );
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

   sendMagicLink = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { email } = req.body;
      console.log("email: ", email);
      const userId = req.user?.id;
      console.log("userId: ", userId);

      await this.authService.sendMagicLink(userId, email);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Verification link sent to your email"));
   });

   verifyEmailPage = asyncHandler(async (req: Request, res: Response) => {
      const token = req.query.token as string;
      if (!token) {
         return res.status(HTTP_STATUS.BAD_REQUEST).send("Invalid token.");
      }

      const appSchemeUrl = `mylifepartner://verify-email?token=${token}`;
      const androidIntentUrl = `intent://verify-email?token=${token}#Intent;scheme=mylifepartner;package=com.ciltriq.mylifepartner;end;`;

      const templatePath = path.join(__dirname, "../../../src/templates/pages/verify-email.html");
      let html = fs.readFileSync(templatePath, "utf-8");
      
      html = html.replace(/{{APP_SCHEME_URL}}/g, appSchemeUrl);
      html = html.replace(/{{ANDROID_INTENT_URL}}/g, androidIntentUrl);

      return res.status(HTTP_STATUS.OK).send(html);
   });

   verifyEmailLink = asyncHandler(async (req: Request, res: Response) => {
      const token = req.body.token || req.query.token;
      const result = await this.authService.verifyEmailLink(token);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, result.message));
   });

   sendPasswordResetLink = asyncHandler(async (req: Request, res: Response) => {
      const { email } = req.body;
      await this.authService.sendPasswordResetLink(email);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Password reset link sent to your email"));
   });

   renderPasswordResetPage = asyncHandler(async (req: Request, res: Response) => {
      const token = req.query.token as string;
      const html = await this.authService.renderPasswordResetPage(token);
      return res.status(HTTP_STATUS.OK).send(html);
   });

   resetPasswordWithLink = asyncHandler(async (req: Request, res: Response) => {
      const { token, password, confirmPassword } = req.body;

      const sendErrorHtml = (title: string, message: string, status: number) => {
         const templatePath = path.join(__dirname, "../../../src/templates/pages/error.html");
         let errorHtml = fs.readFileSync(templatePath, "utf-8");
         errorHtml = errorHtml.replace(/{{TITLE}}/g, title);
         errorHtml = errorHtml.replace(/{{MESSAGE}}/g, message);
         return res.status(status).send(errorHtml);
      };

      if (password !== confirmPassword) {
         return sendErrorHtml("Error", "Passwords do not match.", HTTP_STATUS.BAD_REQUEST);
      }

      try {
         await this.authService.resetPasswordWithLink(token, password);

         const templatePath = path.join(__dirname, "../../../src/templates/pages/reset-password-success.html");
         const successHtml = fs.readFileSync(templatePath, "utf-8");

         return res.status(HTTP_STATUS.OK).send(successHtml);
      } catch (error: any) {
         const message = error.message || "An unexpected error occurred.";
         const status = error.statusCode || HTTP_STATUS.INTERNAL_SERVER_ERROR;
         return sendErrorHtml("Error", message, status);
      }
   });
}
