import { OtpResponseDto, VerfiyOtpResponseDto } from "@/dtos/auth.dto";

export interface IOtpService {
   generateOtp(): string;
   sendOtp(mobileNumber: string, sendOption: string): Promise<OtpResponseDto>;
   resendOtp(mobileNumber: string, sendOption: string): Promise<OtpResponseDto>;
   verifyOtp(mobileNumber: string, otp: string): Promise<VerfiyOtpResponseDto>;
}
