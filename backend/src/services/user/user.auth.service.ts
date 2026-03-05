import prisma from "@/config/prisma";
import { IUserAuthService } from "@/interfaces/services/user.auth.service.interface";
import { EmailService } from "@/services/email.service";
import { OtpService } from "@/services/otp.service";
import { UserService } from "@/services/user.service";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import crypto from "crypto";

import { IJwtService } from "@/interfaces/services/jwt.service.interface";

export class AuthService implements IUserAuthService {
   constructor(
      private userService: UserService,
      private otpService: OtpService,
      private emailService: EmailService,
      private jwtService: IJwtService
   ) {}

   async login(mobileNumber: string, otp: string) {
      if (!mobileNumber || !otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number and OTP are required");
      }

      const verifyResult = await this.otpService.verifyOtp(mobileNumber, otp);
      if (!verifyResult.isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }

      const user = await this.userService.findOrCreateUser(mobileNumber);

      const accessToken = this.jwtService.signAccess({ id: user.id, mobileNumber: user.mobileNumber, role: user.role }, "1d");
      const refreshToken = this.jwtService.signRefresh({ id: user.id, mobileNumber: user.mobileNumber, role: user.role }, "30d");

      return { user, accessToken, refreshToken };
   }

   async sendOtp(mobileNumber: string, sendOption: string) {
      if (!mobileNumber) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number is required");
      }
      if (!sendOption) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Send option is required");
      }

      const otp = await this.otpService.sendOtp(mobileNumber, sendOption);
      return { otp };
   }

   async resendOtp(mobileNumber: string, sendOption: string) {
      if (!mobileNumber) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number is required");
      }
      if (!sendOption) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Send option is required");
      }

      const otp = await this.otpService.resendOtp(mobileNumber, sendOption);
      return { otp };
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

         if (!decoded.mobileNumber) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid token payload: Missing mobile number");
         }
         const user = await this.userService.findOrCreateUser(decoded.mobileNumber);

         const newAccessToken = this.jwtService.signAccess({ id: user.id, mobileNumber: user.mobileNumber }, "1d");
         const newRefreshToken = this.jwtService.signRefresh({ id: user.id, mobileNumber: user.mobileNumber }, "30d");

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
      const baseUrl = "http://192.168.1.27:3000";
      const verificationUrl = `${baseUrl}/api/user/auth/verify-email?token=${token}`;

      await this.emailService.sendVerificationEmail(email, verificationUrl);
   }

   async verifyEmail(token: string | undefined | null | any) {
      if (!token || typeof token !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "The verification link is missing or invalid.");
      }

      // Find token
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

      // Mark token as used and update user status in a transaction
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
}
