import prisma from "@/config/prisma";
import { toUserDto } from "@/dtos/user.dto";
import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, RATE_LIMIT_CONFIG } from "@/utils/constants";
import bcrypt from "bcrypt";
import crypto from "crypto";
import fs from "fs";
import path from "path";

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

   async initiateAuth(email: string, ip: string) {
      if (!email) throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is required");

      const user = await this.userService.findUserByEmail(email);
      const exists = !!user;

      const otpResult = await this.otpService.sendOtp(email, ip);

      return { exists, otp: otpResult };
   }

   private async assertOtpVerified(email: string) {
      const isVerified = await this.cacheService.getCache(CACHE_KEYS.OTP_VERIFIED(email));
      if (!isVerified) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Please verify OTP before proceeding");
      }
      return true;
   }

   private async clearOtpVerified(email: string) {
      await this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFIED(email));
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

   async verifyOtp(email: string, otp: string) {
      if (!email || !otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email and OTP are required");
      }
      const verifyResult = await this.otpService.verifyOtp(email, otp);
      if (!verifyResult.isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }
      return { isValid: true, message: "OTP Verified Successfully" };
   }

   async login(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email);
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

      await this.clearOtpVerified(email);
      await this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(email));

      const accessToken = this.jwtService.signAccess({ id: user.id, email: user.email, role: user.role }, "1d");
      const refreshToken = this.jwtService.signRefresh({ id: user.id, email: user.email, role: user.role }, "30d");

      return { user: toUserDto(user), accessToken, refreshToken };
   }

   async register(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email);

      const existingUser = await prisma.user.findUnique({ where: { email } });
      if (existingUser) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "User already exists");
      }

      const hashedPassword = await bcrypt.hash(passwordPlain, 10);
      const user = await prisma.user.create({
         data: {
            email,
            password: hashedPassword,
            isEmailVerified: true,
         },
         include: { profile: true },
      });

      await this.clearOtpVerified(email);

      const accessToken = this.jwtService.signAccess({ id: user.id, email: user.email, role: user.role }, "1d");
      const refreshToken = this.jwtService.signRefresh({ id: user.id, email: user.email, role: user.role }, "30d");

      return { user: toUserDto(user), accessToken, refreshToken };
   }

   async forgotPassword(email: string, passwordPlain: string) {
      await this.assertOtpVerified(email);

      const user = await prisma.user.findUnique({ where: { email } });
      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      const hashedPassword = await bcrypt.hash(passwordPlain, 10);
      await prisma.user.update({
         where: { email },
         data: { password: hashedPassword },
      });

      await this.clearOtpVerified(email);
      await this.cacheService.deleteCache(CACHE_KEYS.ACCOUNT_LOCK(email)); // unlock if it was locked

      return { message: "Password updated successfully" };
   }

   async detectCountryAsync(ip: string | undefined, countryCodeHeader: string | undefined) {
      const isLocal = !ip || ip === "::1" || ip === "127.0.0.1" || ip.startsWith("192.168.") || ip.startsWith("10.");

      if (countryCodeHeader && !isLocal) {
         const countryNames: Record<string, string> = { IN: "India", US: "United States", GB: "United Kingdom", AE: "United Arab Emirates" };
         const callingCodes: Record<string, string> = { IN: "+91", US: "+1", GB: "+44", AE: "+971" };

         if (callingCodes[countryCodeHeader.toUpperCase()]) {
            return {
               country: countryNames[countryCodeHeader.toUpperCase()] || countryCodeHeader,
               countryCode: countryCodeHeader.toUpperCase(),
               callingCode: callingCodes[countryCodeHeader.toUpperCase()],
               message: "Country detected from platform headers",
            };
         }
      }

      if (isLocal) {
         return {
            country: "India",
            countryCode: "IN",
            callingCode: "+91",
            message: "Localhost detected, returning default country",
         };
      }

      try {
         const response = await fetch(`https://ipapi.co/${ip}/json/`);
         const data = await response.json();

         console.log(`👉 ip response : `, data);

         if (data.error) {
            throw new Error(data.reason);
         }

         return {
            country: data.country_name || "India",
            countryCode: data.country_code || "IN",
            callingCode: data.country_calling_code || "+91",
            message: "Country detected successfully",
         };
      } catch (error) {
         return {
            country: "India",
            countryCode: "IN",
            callingCode: "+91",
            message: "Detection failed, returning fallback",
         };
      }
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

   async sendMagicLink(userId: number | undefined, email: string) {
      if (!userId) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "User not authenticated");
      }

      if (!email) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is required");
      }

      const user = await this.userService.getUserById(userId);
      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      if (user.email !== email) {
         await this.userService.updateUser(userId, { email, isEmailVerified: false } as import("@prisma/client").Prisma.UserUpdateInput);
      } else if (user.isEmailVerified) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is already verified");
      }

      // Expire any existing unused tokens for this user first
      await prisma.emailVerificationToken.updateMany({
         where: { userId, isUsed: false },
         data: { isUsed: true },
      });

      const token = crypto.randomBytes(32).toString("hex");
      const expiresAt = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes

      await prisma.emailVerificationToken.create({
         data: {
            userId,
            token,
            expiresAt,
         },
      });

      // Point to our HTTPS route instead of direct deep link
      // Use env or request host, but falling back to default localhost or production domain
      const baseUrl = "https://mudfish-welcomed-guinea.ngrok-free.app";
      const verificationUrl = `${baseUrl}/api/user/auth/verify-email?token=${token}`;

      await this.emailService.sendVerificationEmail(email, verificationUrl);
   }

   async sendOtp(email: string, ip: string) {
      const otp = await this.otpService.sendOtp(email, ip);
      return { otp };
   }

   async resendOtp(email: string, ip: string) {
      const otp = await this.otpService.resendOtp(email, ip);
      return { otp };
   }

   async verifyEmailLink(token: string | undefined | null | any) {
      if (!token || typeof token !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "The verification link is missing or invalid.");
      }

      const verificationRecord = await prisma.emailVerificationToken.findUnique({
         where: { token },
         include: { user: true },
      });

      if (!verificationRecord) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "This verification link is invalid. Please request a new one.");
      }

      if (verificationRecord.isUsed) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "This verification link has already been used. Please request a new one.");
      }

      if (new Date() > verificationRecord.expiresAt) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "This verification link has expired. Please request a new one.");
      }

      const user = verificationRecord.user;

      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "We couldn't find the account associated with this link.");
      }

      if (user.isEmailVerified) {
         return { verified: true, message: "Your email is already verified." };
      }

      await prisma.$transaction([
         prisma.emailVerificationToken.update({
            where: { id: verificationRecord.id },
            data: { isUsed: true },
         }),
         prisma.user.update({
            where: { id: user.id },
            data: { isEmailVerified: true },
         }),
      ]);

      return { verified: true, message: "Email Verified Successfully!" };
   }

   async sendPasswordResetLink(email: string) {
      if (!email) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Email is required");
      }

      const user = await this.userService.findUserByEmail(email);
      if (!user) {
         // Return silently to prevent email enumeration
         return;
      }

      const token = crypto.randomBytes(32).toString("hex");
      const expiresAtSeconds = 15 * 60; // 15 minutes

      await this.cacheService.setCache(CACHE_KEYS.PASSWORD_RESET_TOKEN(token), user.id.toString(), expiresAtSeconds);

      // const baseUrl = "https://mudfish-welcomed-guinea.ngrok-free.app";
      const baseUrl = "http://localhost:3000";
      const resetUrl = `${baseUrl}/api/user/auth/forgot-password/reset?token=${token}`;

      await this.emailService.sendPasswordResetEmail(email, resetUrl);
   }

   async renderPasswordResetPage(token: string | undefined | null | any) {
      if (!token || typeof token !== "string") {
         return this.getErrorHtml("Invalid Link", "The reset link is missing or invalid.");
      }

      const userIdStr = await this.cacheService.getCache(CACHE_KEYS.PASSWORD_RESET_TOKEN(token));

      if (!userIdStr) {
         return this.getErrorHtml("Invalid or Expired Link", "This reset link is invalid or has expired. Please request a new one.");
      }

      const templatePath = path.join(__dirname, "../../../src/templates/pages/reset-password-form.html");
      let html = fs.readFileSync(templatePath, "utf-8");

      html = html.replace(/{{TOKEN}}/g, token);

      return html;
   }

   async resetPasswordWithLink(token: string | undefined | null | any, passwordPlain: string) {
      if (!token || typeof token !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "The reset link is missing or invalid.");
      }

      if (!passwordPlain || passwordPlain.length < 8) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Password must be at least 8 characters.");
      }

      const userIdStr = await this.cacheService.getCache(CACHE_KEYS.PASSWORD_RESET_TOKEN(token));

      if (!userIdStr) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "This reset link is invalid or has expired. Please request a new one.");
      }

      const userId = parseInt(userIdStr, 10);
      const user = await prisma.user.findUnique({ where: { id: userId } });

      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "We couldn't find the account associated with this link.");
      }

      const hashedPassword = await bcrypt.hash(passwordPlain, 10);

      await prisma.user.update({
         where: { id: userId },
         data: { password: hashedPassword },
      });

      await this.cacheService.deleteCache(CACHE_KEYS.PASSWORD_RESET_TOKEN(token));

      return { success: true, message: "Password reset successfully" };
   }

   private getErrorHtml(title: string, message: string) {
      const templatePath = path.join(__dirname, "../../../src/templates/pages/error.html");
      let html = fs.readFileSync(templatePath, "utf-8");

      html = html.replace(/{{TITLE}}/g, title);
      html = html.replace(/{{MESSAGE}}/g, message);

      return html;
   }
}
