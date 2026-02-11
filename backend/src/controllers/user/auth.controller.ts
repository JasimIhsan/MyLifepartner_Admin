import otpService from "@/services/otp.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

class AuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, otp } = req.body;
      if (!mobileNumber || !otp) {
         throw new ApiError(400, "Mobile number and OTP are required");
      }

      const isValid = await otpService.verifyOtp(mobileNumber, otp);
      if (!isValid) {
         throw new ApiError(401, "Invalid or expired OTP");
      }

      // Here you would find or create the user and generate a JWT
      return res.status(200).json(new ApiResponse(200, { user: "demo_user" }, "User login success"));
   });

   sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      if (!mobileNumber) {
         throw new ApiError(400, "Mobile number is required");
      }

      const otp = await otpService.sendOtp(mobileNumber, sendOption);

      return res.status(200).json(new ApiResponse(200, { otp }, "Otp sent successfully"));
   });
}

export default new AuthController();
