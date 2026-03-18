import prisma from "@/config/prisma";
import { toUserDto } from "@/dtos/user.dto";
import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, RATE_LIMIT_CONFIG } from "@/utils/constants";
import bcrypt from "bcrypt";
import crypto from "crypto";
import fs from "fs";
import path from "path";

import env from "@/config/env";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { IOtpService } from "@/interfaces/services/otp.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";

export class AuthService implements IUserAuthService {
   constructor(
      private userService: IUserService,
      private otpService: IOtpService,
      private emailService: IEmailService,
      private jwtService: IJwtService,
      private cacheService: ICacheService
   ) {}

   async initiateAuth(email: string, ip: string, purpose: string = "auth") {
      if (!email) throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is required");

      const user = await this.userService.findUserByEmail(email);
      const exists = !!user;

      const otpResult = await this.otpService.sendOtp(email, ip, purpose);

      return { exists, otp: otpResult };
   }

   private async assertOtpVerified(email: string, purpose: string) {
      const isVerified = await this.cacheService.getCache(CACHE_KEYS.OTP_VERIFIED(email, purpose));
      if (!isVerified) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Please verify OTP before proceeding");
      }
      return true;
   }

   private async clearOtpVerified(email: string, purpose: string) {
      await this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFIED(email, purpose));
   }

   private async checkAccountLock(email: string) {
      const lockKey = CACHE_KEYS.ACCOUNT_LOCK(email);
      const attemptsStr = await this.cacheService.getCache(lockKey);
      const attempts = parseInt(attemptsStr || "0", 10);
      if (attempts >= RATE_LIMIT_CONFIG.OTP_VERIFY_ATTEMPTS) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS, "Account locked due to too many failed attempts. Try again in 15 minutes.");
      }
   }

   private async handleFailedAttempt(email: string) {
      const lockKey = CACHE_KEYS.ACCOUNT_LOCK(email);
      const attemptsStr = await this.cacheService.getCache(lockKey);
      await this.cacheService.incrCache(lockKey);
      if (!attemptsStr) {
         await this.cacheService.expireCache(lockKey, RATE_LIMIT_CONFIG.LOCKOUT_DURATION);
      }
      throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid password");
   }

   async verifyOtp(email: string, otp: string, purpose: string = "auth") {
      if (!email || !otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email and OTP are required");
      }
      const verifyResult = await this.otpService.verifyOtp(email, otp, purpose);
      if (!verifyResult.isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }
      return { isValid: true, message: "OTP Verified Successfully" };
   }

   async login(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email, "auth");
      await this.checkAccountLock(email);

      const user = await prisma.user.findUnique({ where: { email }, include: { profile: true } });
      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }
      if (!user.password) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Password not set for this account");
      }

      const isMatch = await bcrypt.compare(passwordPlain, user.password);
      if (!isMatch) {
         await this.handleFailedAttempt(email);
      }

      await this.clearOtpVerified(email, "auth");
      await this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(email));

      const accessToken = this.jwtService.signAccess({ id: user.id, email: user.email, role: user.role }, "1d");
      const refreshToken = this.jwtService.signRefresh({ id: user.id, email: user.email, role: user.role }, "30d");

      return { user: toUserDto(user), accessToken, refreshToken };
   }

   async register(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email, "auth");

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "User already exists");
      }

      const hashedPassword = await bcrypt.hash(passwordPlain, 10);
      const user = await prisma.user.create({
         data: {
            email,
            password: hashedPassword,
         },
         include: { profile: true },
      });

      await this.clearOtpVerified(email, "auth");

      const accessToken = this.jwtService.signAccess({ id: user.id, email: user.email, role: user.role }, "1d");
      const refreshToken = this.jwtService.signRefresh({ id: user.id, email: user.email, role: user.role }, "30d");

      return { user: toUserDto(user), accessToken, refreshToken };
   }

   async forgotPassword(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email, "password_reset");

      const user = await prisma.user.findUnique({ where: { email } });
      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      const hashedPassword = await bcrypt.hash(passwordPlain, 10);
      await prisma.user.update({
         where: { email },
         data: { password: hashedPassword },
      });

      await this.clearOtpVerified(email, "password_reset");
      await this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(email)); // unlock if it was locked

      return { message: "Password updated successfully" };
   }



   async refreshToken(refreshToken: string) {
      if (!refreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      try {
         const decoded = this.jwtService.verifyRefresh(refreshToken);

         if (!decoded.email) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid token payload: Missing email");
         }
         const user = await this.userService.findUserByEmail(decoded.email);
         if (!user) throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "User not found");

         const newAccessToken = this.jwtService.signAccess({ id: user.id, email: user.email }, "1d");
         const newRefreshToken = this.jwtService.signRefresh({ id: user.id, email: user.email }, "30d");

         return { accessToken: newAccessToken, refreshToken: newRefreshToken };
      } catch (error) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired refresh token");
      }
   }


   async sendOtp(email: string, ip: string, purpose: string = "auth") {
      const otp = await this.otpService.sendOtp(email, ip, purpose);
      return { otp };
   }

   async resendOtp(email: string, ip: string, purpose: string = "auth") {
      const otp = await this.otpService.resendOtp(email, ip, purpose);
      return { otp };
   }


}
