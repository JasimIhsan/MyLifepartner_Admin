import otpService from "@/services/otp.service";
import userService from "@/services/user.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import jwt from "jsonwebtoken";

class AuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, otp } = req.body;
      if (!mobileNumber || !otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number and OTP are required");
      }

      const verifyResult = await otpService.verifyOtp(mobileNumber, otp);
      if (!verifyResult.isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }

      const user = await userService.findOrCreateUser(mobileNumber);

      const accessToken = jwt.sign({ id: user.id, mobileNumber: user.mobileNumber }, process.env.JWT_SECRET || "default_secret", { expiresIn: "1d" });
      const refreshToken = jwt.sign({ id: user.id, mobileNumber: user.mobileNumber }, process.env.JWT_REFRESH_SECRET || "default_refresh_secret", { expiresIn: "30d" });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user, accessToken, refreshToken }, "User login success"));
   });

   sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      console.log(`👉 Mobile Number : `, mobileNumber);
      console.log(`👉 Send Option : `, sendOption);
      if (!mobileNumber) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number is required");
      }
      if (!sendOption) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Send option is required");
      }

      const otp = await otpService.sendOtp(mobileNumber, sendOption);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { otp }, "Otp sent successfully"));
   });

   resendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      console.log(`👉 Resending OTP to : ${mobileNumber} via ${sendOption}`);

      if (!mobileNumber) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number is required");
      }
      if (!sendOption) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Send option is required");
      }

      const otp = await otpService.resendOtp(mobileNumber, sendOption);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { otp }, "Otp resent successfully"));
   });

   detectCountry = asyncHandler(async (req: Request, res: Response) => {
      // 1. Try platform headers first (Cloudflare / Vercel)
      const countryCodeHeader = (req.headers["cf-ipcountry"] || req.headers["x-vercel-ip-country"]) as string;

      // 2. Localhost / Internal IP detection
      const ip = req.ip;
      const isLocal = !ip || ip === "::1" || ip === "127.0.0.1" || ip.startsWith("192.168.") || ip.startsWith("10.");

      // If we have a platform header, we can use it to avoid an external API call
      // We'll need a basic mapping for calling codes if we go this route
      if (countryCodeHeader && !isLocal) {
         // Basic mapping for common countries (can be expanded)
         const countryNames: Record<string, string> = { IN: "India", US: "United States", GB: "United Kingdom", AE: "United Arab Emirates" };
         const callingCodes: Record<string, string> = { IN: "+91", US: "+1", GB: "+44", AE: "+971" };

         if (callingCodes[countryCodeHeader.toUpperCase()]) {
            return res.status(HTTP_STATUS.OK).json(
               new ApiResponse(
                  HTTP_STATUS.OK,
                  {
                     country: countryNames[countryCodeHeader.toUpperCase()] || countryCodeHeader,
                     countryCode: countryCodeHeader.toUpperCase(),
                     callingCode: callingCodes[countryCodeHeader.toUpperCase()],
                  },
                  "Country detected from platform headers"
               )
            );
         }
      }

      // 3. Fallback to IP-based geo service
      if (isLocal) {
         return res.status(HTTP_STATUS.OK).json(
            new ApiResponse(
               HTTP_STATUS.OK,
               {
                  country: "India",
                  countryCode: "IN",
                  callingCode: "+91",
               },
               "Localhost detected, returning default country"
            )
         );
      }

      try {
         // We use ipapi.co as it provides calling codes and doesn't require an API key for low volume
         const response = await fetch(`https://ipapi.co/${ip}/json/`);
         const data = await response.json();

         console.log(`👉 ip response : `, data);

         if (data.error) {
            throw new Error(data.reason);
         }

         return res.status(HTTP_STATUS.OK).json(
            new ApiResponse(
               HTTP_STATUS.OK,
               {
                  country: data.country_name || "India",
                  countryCode: data.country_code || "IN",
                  callingCode: data.country_calling_code || "+91",
               },
               "Country detected successfully"
            )
         );
      } catch (error) {
         // Final fallback in case of service failure
         return res.status(HTTP_STATUS.OK).json(
            new ApiResponse(
               HTTP_STATUS.OK,
               {
                  country: "India",
                  countryCode: "IN",
                  callingCode: "+91",
               },
               "Detection failed, returning fallback"
            )
         );
      }
   });

   refreshToken = asyncHandler(async (req: Request, res: Response) => {
      const { refreshToken } = req.body;

      if (!refreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      try {
         const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || "default_refresh_secret") as any;

         const user = await userService.findOrCreateUser(decoded.mobileNumber);

         const newAccessToken = jwt.sign({ id: user.id, mobileNumber: user.mobileNumber }, process.env.JWT_SECRET || "default_secret", { expiresIn: "1d" });
         const newRefreshToken = jwt.sign({ id: user.id, mobileNumber: user.mobileNumber }, process.env.JWT_REFRESH_SECRET || "default_refresh_secret", { expiresIn: "30d" });

         return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { accessToken: newAccessToken, refreshToken: newRefreshToken }, "Token refreshed successfully"));
      } catch (error) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired refresh token");
      }
   });
}

export default new AuthController();
