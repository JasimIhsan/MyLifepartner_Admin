import otpService from "@/services/otp.service";
import userService from "@/services/user.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

class AuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, otp } = req.body;
      if (!mobileNumber || !otp) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number and OTP are required");
      }

      const isValid = await otpService.verifyOtp(mobileNumber, otp);
      if (!isValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired OTP");
      }

      const user = await userService.findOrCreateUser(mobileNumber);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { user }, "User login success"));
   });

   sendOtp = asyncHandler(async (req: Request, res: Response) => {
      const { mobileNumber, sendOption } = req.body;
      if (!mobileNumber) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Mobile number is required");
      }
      if (!sendOption) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Send option is required");
      }

      const otp = await otpService.sendOtp(mobileNumber, sendOption);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { otp }, "Otp sent successfully"));
   });
}

export default new AuthController();
