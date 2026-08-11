import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

export class AuthController {
   constructor(
      private readonly authService: IUserAuthService,
      private readonly userService: IUserService,
      private readonly userSubscriptionService: IUserSubscriptionService
   ) {}

   /**
    * @route POST /api/v1/user/auth/initiate
    * @purpose Initiates OTP/authentication flow.
    */
   public initiateAuth = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const purpose = this.getOptionalString(req.body.purpose, "auth");
      const ip = this.getClientIp(req);

      const result = await this.authService.initiateAuth(email, ip, purpose);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Auth initiated"));
   });

   /**
    * @route POST /api/v1/user/auth/verify-otp
    * @purpose Verifies OTP for authentication or password reset.
    */
   public verifyOtp = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const otp = this.getRequiredString(req.body.otp, "OTP is required");
      const purpose = this.getOptionalString(req.body.purpose, "auth");

      const result = await this.authService.verifyOtp(email, otp, purpose);

      if ((result as any).user?.id) {
         await auditService.log({
            userId: (result as any).user.id,
            actorType: ActorType.USER,
            module: AuditModule.AUTH,
            action: "OTP_VERIFIED",
            status: AuditStatus.SUCCESS,
            severity: AuditSeverity.INFO,
            message: `User verified OTP for purpose: ${purpose}`,
            source: AuditSource.API,
         });
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "OTP verified"));
   });

   /**
    * @route POST /api/v1/user/auth/login
    * @purpose Logs in a user with email and password.
    */
   public login = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const password = this.getRequiredString(req.body.password, "Password is required");

      try {
         const result = await this.authService.login(email, password);

         // Lazily reconcile subscription state with RevenueCat upon login
         await this.userSubscriptionService.reconcileUserSubscription(result.user.id);

         await auditService.log({
            userId: (result as any).user.id,
            actorType: ActorType.USER,
            module: AuditModule.AUTH,
            action: "USER_LOGIN",
            status: AuditStatus.SUCCESS,
            severity: AuditSeverity.INFO,
            message: `User logged in successfully`,
            source: AuditSource.API,
         });

         return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User login success"));
      } catch (error: any) {
         await auditService.log({
            actorType: ActorType.SYSTEM,
            module: AuditModule.AUTH,
            action: "USER_LOGIN_FAILED",
            status: AuditStatus.FAILED,
            severity: AuditSeverity.WARNING,
            message: `Failed login attempt for email: ${email}. Reason: ${error.message || "Unknown"}`,
            source: AuditSource.API,
         });
         throw error;
      }
   });

   /**
    * @route POST /api/v1/user/auth/register
    * @purpose Registers a new user account.
    */
   public register = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const password = this.getRequiredString(req.body.password, "Password is required");

      const result = await this.authService.register(email, password);

      await auditService.log({
         userId: (result as any).user.id,
         actorType: ActorType.USER,
         module: AuditModule.AUTH,
         action: "USER_SIGNUP",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User registered successfully`,
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User registered successfully"));
   });

   /**
    * @route POST /api/v1/user/auth/forgot-password
    * @purpose Resets user's password after OTP verification.
    */
   public forgotPassword = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const password = this.getRequiredString(req.body.password, "Password is required");

      const result = await this.authService.forgotPassword(email, password);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, result.message));
   });

   /**
    * @route POST /api/v1/user/auth/send-otp
    * @purpose Sends OTP to the user's email.
    */
   public sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const purpose = this.getOptionalString(req.body.purpose, "auth");
      const ip = this.getClientIp(req);

      const result = await this.authService.sendOtp(email, ip, purpose);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "OTP sent successfully"));
   });

   /**
    * @route POST /api/v1/user/auth/resend-otp
    * @purpose Resends OTP to the user's email.
    */
   public resendOtp = asyncHandler(async (req: Request, res: Response) => {
      const email = this.getRequiredString(req.body.email, "Email is required");
      const purpose = this.getOptionalString(req.body.purpose, "auth");
      const ip = this.getClientIp(req);

      const result = await this.authService.resendOtp(email, ip, purpose);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "OTP resent successfully"));
   });

   /**
    * @route POST /api/v1/user/auth/refresh-token
    * @purpose Generates new tokens using refresh token.
    */
   public refreshToken = asyncHandler(async (req: Request, res: Response) => {
      const refreshToken = this.getRequiredString(req.body.refreshToken, "Refresh token is required");

      const result = await this.authService.refreshToken(refreshToken);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Token refreshed successfully"));
   });

   /**
    * @route GET /api/v1/user/auth/me
    * @purpose Fetches authenticated user's onboarding status.
    */
   public me = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      // Lazily reconcile subscription state with RevenueCat before responding
      await this.userSubscriptionService.reconcileUserSubscription(userId);

      const status = await this.userService.getOnboardingStatus(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, status, "User status fetched successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Extracts and validates a required string value.
    */
   private getRequiredString(value: unknown, errorMessage: string): string {
      if (typeof value !== "string" || value.trim().length === 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return value.trim();
   }

   /**
    * Extracts an optional string value or returns the default value.
    */
   private getOptionalString(value: unknown, defaultValue: string): string {
      if (value === undefined || value === null) {
         return defaultValue;
      }

      if (typeof value !== "string" || value.trim().length === 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid request value");
      }

      return value.trim();
   }

   /**
    * Extracts client IP address from request.
    */
   private getClientIp(req: Request): string {
      return req.ip || "";
   }
}
