import { IEmailService } from "@/interfaces/services/email.service.interface";
import { toUserDto } from "@/dtos/user.dto";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IUserSubscriptionRepository, SubscriptionStatus } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { IOtpService } from "@/interfaces/services/otp.service.interface";
import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, RATE_LIMIT_CONFIG } from "@/utils/constants";
import logger from "@/utils/logger";
import bcrypt from "bcrypt";

const DEFAULT_AUTH_PURPOSE = "auth";
const PASSWORD_RESET_PURPOSE = "password_reset";
const FREE_PLAN_NAME = "FREE";
const PASSWORD_SALT_ROUNDS = 10;
const ACCESS_TOKEN_EXPIRY = "15m";
const REFRESH_TOKEN_EXPIRY = "7d";
const FREE_PLAN_DURATION_YEARS = 100;

type AuthTokens = {
   accessToken: string;
   refreshToken: string;
};

export class AuthService implements IUserAuthService {
   constructor(
      private readonly userRepository: IUserRepository,
      private readonly otpService: IOtpService,
      private readonly jwtService: IJwtService,
      private readonly cacheService: ICacheService,
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly userSubscriptionRepository: IUserSubscriptionRepository,
      private readonly emailService: IEmailService
   ) {}

   /**
    * Starts email authentication by sending OTP.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @param purpose - OTP purpose.
    * @returns User existence status and OTP response.
    */
   async initiateAuth(email: string, ip: string, purpose: string = DEFAULT_AUTH_PURPOSE) {
      const normalizedEmail = this.normalizeEmail(email);

      const user = await this.userRepository.findByEmail(normalizedEmail);

      if (user) {
         if (user.isBanned) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
         }
         if (user.isDeleteRequested && user.deleteRequestStatus === "PENDING") {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account deletion is pending approval.");
         }
         if (user.isSuspended) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
         }
      }

      const otp = await this.otpService.sendOtp(normalizedEmail, ip, purpose);

      return {
         exists: Boolean(user),
         otp,
      };
   }

   /**
    * Verifies OTP.
    *
    * @param email - User email.
    * @param otp - OTP value.
    * @param purpose - OTP purpose.
    * @returns OTP verification result.
    */
   async verifyOtp(email: string, otp: string, purpose: string = DEFAULT_AUTH_PURPOSE) {
      const normalizedEmail = this.normalizeEmail(email);

      if (!otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "OTP is required");
      }

      const verifyResult = await this.otpService.verifyOtp(normalizedEmail, otp, purpose);

      if (!verifyResult.isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }

      return {
         isValid: true,
         message: "OTP verified successfully",
      };
   }

   /**
    * Logs in a user.
    *
    * @param email - User email.
    * @param passwordPlain - Plain password.
    * @returns User with auth tokens.
    */
   async login(email: string, passwordPlain: string) {
      const normalizedEmail = this.normalizeEmail(email);

      await this.assertOtpVerified(normalizedEmail, DEFAULT_AUTH_PURPOSE);
      await this.checkAccountLock(normalizedEmail);

      const user = await this.userRepository.findByEmail(normalizedEmail);

      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      if (!user.password) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Password not set for this account");
      }

      if (user.isBanned) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
      }

      if (user.isDeleteRequested && user.deleteRequestStatus === "PENDING") {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account deletion is pending approval.");
      }

      if (user.isSuspended) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
      }

      const isPasswordValid = await bcrypt.compare(passwordPlain, user.password);

      if (!isPasswordValid) {
         await this.handleFailedAttempt(normalizedEmail);
      }

      await Promise.all([this.clearOtpVerified(normalizedEmail, DEFAULT_AUTH_PURPOSE), this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail))]);

      const tokens = this.generateAuthTokens(user.id, user.email, user.role);

      return {
         user: toUserDto(user),
         ...tokens,
      };
   }

   /**
    * Registers a user.
    *
    * @param email - User email.
    * @param passwordPlain - Plain password.
    * @returns Created user with auth tokens.
    */
   async register(email: string, passwordPlain: string) {
      const normalizedEmail = this.normalizeEmail(email);

      await this.assertOtpVerified(normalizedEmail, DEFAULT_AUTH_PURPOSE);

      const existingUser = await this.userRepository.findByEmail(normalizedEmail);

      if (existingUser) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "User already exists");
      }

      const hashedPassword = await this.hashPassword(passwordPlain);

      const user = await this.userRepository.create({
         email: normalizedEmail,
         password: hashedPassword,
      });

      await this.assignFreePlanIfAvailable(user.id);
      await this.clearOtpVerified(normalizedEmail, DEFAULT_AUTH_PURPOSE);

      // Send welcome email asynchronously
      this.emailService.sendWelcomeEmail(user.email, "there").catch((error) => {
         logger.error(`Failed to send welcome email to ${user.email}:`, error);
      });

      const tokens = this.generateAuthTokens(user.id, user.email, user.role);

      return {
         user: toUserDto(user),
         ...tokens,
      };
   }

   /**
    * Resets user password.
    *
    * @param email - User email.
    * @param passwordPlain - New plain password.
    * @returns Password update message.
    */
   async forgotPassword(email: string, passwordPlain: string) {
      const normalizedEmail = this.normalizeEmail(email);

      await this.assertOtpVerified(normalizedEmail, PASSWORD_RESET_PURPOSE);

      const user = await this.userRepository.findByEmail(normalizedEmail);

      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      const hashedPassword = await this.hashPassword(passwordPlain);

      await this.userRepository.update(user.id, {
         password: hashedPassword,
      });

      await Promise.all([this.clearOtpVerified(normalizedEmail, PASSWORD_RESET_PURPOSE), this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail))]);

      return {
         message: "Password updated successfully",
      };
   }

   /**
    * Refreshes auth tokens.
    *
    * @param refreshToken - Refresh token.
    * @returns New auth tokens.
    */
   async refreshToken(refreshToken: string): Promise<AuthTokens> {
      if (!refreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      try {
         const decoded = this.jwtService.verifyRefresh(refreshToken);

         if (!decoded.email) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid token payload");
         }

         const user = await this.userRepository.findByEmail(decoded.email);

         if (!user) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "User not found");
         }

         if (user.isBanned) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
         }

         if (user.isDeleteRequested && user.deleteRequestStatus === "PENDING") {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account deletion is pending approval.");
         }

         if (user.isSuspended) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
         }

         return this.generateAuthTokens(user.id, user.email, user.role);
      } catch {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired refresh token");
      }
   }

   /**
    * Sends OTP.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @param purpose - OTP purpose.
    * @returns OTP response.
    */
   async sendOtp(email: string, ip: string, purpose: string = DEFAULT_AUTH_PURPOSE) {
      const normalizedEmail = this.normalizeEmail(email);

      const existingUser = await this.userRepository.findByEmail(normalizedEmail);
      if (existingUser) {
         if (existingUser.isBanned) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
         }
         if (existingUser.isDeleteRequested && existingUser.deleteRequestStatus === "PENDING") {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account deletion is pending approval.");
         }
         if (existingUser.isSuspended) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
         }
      }

      const otp = await this.otpService.sendOtp(normalizedEmail, ip, purpose);

      return {
         otp,
      };
   }

   /**
    * Resends OTP.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @param purpose - OTP purpose.
    * @returns OTP response.
    */
   async resendOtp(email: string, ip: string, purpose: string = DEFAULT_AUTH_PURPOSE) {
      const normalizedEmail = this.normalizeEmail(email);

      const existingUser = await this.userRepository.findByEmail(normalizedEmail);
      if (existingUser) {
         if (existingUser.isBanned) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
         }
         if (existingUser.isDeleteRequested && existingUser.deleteRequestStatus === "PENDING") {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account deletion is pending approval.");
         }
         if (existingUser.isSuspended) {
            throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
         }
      }

      const otp = await this.otpService.resendOtp(normalizedEmail, ip, purpose);

      return {
         otp,
      };
   }

   /**
    * Checks whether OTP is verified.
    *
    * @param email - User email.
    * @param purpose - OTP purpose.
    * @returns Nothing.
    */
   private async assertOtpVerified(email: string, purpose: string): Promise<void> {
      const isVerified = await this.cacheService.getCache(CACHE_KEYS.OTP_VERIFIED(email, purpose));

      if (!isVerified) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Please verify OTP before proceeding");
      }
   }

   /**
    * Clears OTP verified status.
    *
    * @param email - User email.
    * @param purpose - OTP purpose.
    * @returns Nothing.
    */
   private async clearOtpVerified(email: string, purpose: string): Promise<void> {
      await this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFIED(email, purpose));
   }

   /**
    * Checks account lock status.
    *
    * @param email - User email.
    * @returns Nothing.
    */
   private async checkAccountLock(email: string): Promise<void> {
      const lockKey = CACHE_KEYS.ACCOUNT_LOCK(email);
      const attempts = await this.getCacheNumber(lockKey);

      if (attempts >= RATE_LIMIT_CONFIG.OTP_VERIFY_ATTEMPTS) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS, "Account locked due to too many failed attempts. Try again in 15 minutes.");
      }
   }

   /**
    * Handles failed login attempt.
    *
    * @param email - User email.
    * @returns Nothing.
    */
   private async handleFailedAttempt(email: string): Promise<void> {
      const lockKey = CACHE_KEYS.ACCOUNT_LOCK(email);
      const attempts = await this.cacheService.getCache(lockKey);

      await this.cacheService.incrCache(lockKey);

      if (!attempts) {
         await this.cacheService.expireCache(lockKey, RATE_LIMIT_CONFIG.LOCKOUT_DURATION);
      }

      throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid password");
   }

   /**
    * Assigns free plan to user.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   private async assignFreePlanIfAvailable(userId: number): Promise<void> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         return;
      }

      const startDate = new Date();
      const endDate = this.getFreePlanEndDate(startDate);

      await this.userSubscriptionRepository.createUserSubscription({
         user: {
            connect: {
               id: userId,
            },
         },
         plan: {
            connect: {
               id: freePlan.id,
            },
         },
         startDate,
         endDate,
         status: SubscriptionStatus.ACTIVE,
         willRenew: false,
      });
   }

   /**
    * Gets free plan end date.
    *
    * @param startDate - Subscription start date.
    * @returns Subscription end date.
    */
   private getFreePlanEndDate(startDate: Date): Date {
      const endDate = new Date(startDate);
      endDate.setFullYear(endDate.getFullYear() + FREE_PLAN_DURATION_YEARS);

      return endDate;
   }

   /**
    * Generates auth tokens.
    *
    * @param id - User ID.
    * @param email - User email.
    * @param role - User role.
    * @returns Auth tokens.
    */
   private generateAuthTokens(id: number, email: string | null, role: string): AuthTokens {
      const payload = {
         id,
         email,
         role,
      };

      return {
         accessToken: this.jwtService.signAccess(payload, ACCESS_TOKEN_EXPIRY),
         refreshToken: this.jwtService.signRefresh(payload, REFRESH_TOKEN_EXPIRY),
      };
   }

   /**
    * Hashes password.
    *
    * @param passwordPlain - Plain password.
    * @returns Hashed password.
    */
   private async hashPassword(passwordPlain: string): Promise<string> {
      return bcrypt.hash(passwordPlain, PASSWORD_SALT_ROUNDS);
   }

   /**
    * Normalizes email.
    *
    * @param email - User email.
    * @returns Normalized email.
    */
   private normalizeEmail(email: string): string {
      const normalizedEmail = email?.trim().toLowerCase();

      if (!normalizedEmail) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is required");
      }

      return normalizedEmail;
   }

   /**
    * Gets numeric cache value.
    *
    * @param key - Cache key.
    * @returns Parsed number.
    */
   private async getCacheNumber(key: string): Promise<number> {
      const value = await this.cacheService.getCache(key);

      return Number.parseInt(value ?? "0", 10);
   }
}
