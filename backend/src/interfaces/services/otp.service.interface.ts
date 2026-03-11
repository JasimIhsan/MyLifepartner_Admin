import { OtpResponseDto, VerfiyOtpResponseDto } from "@/dtos/auth.dto";

export interface IOtpService {
   generateOtp(): string;
   sendOtp(email: string, ip: string): Promise<OtpResponseDto>;
   resendOtp(email: string, ip: string): Promise<OtpResponseDto>;
   verifyOtp(email: string, otp: string): Promise<VerfiyOtpResponseDto>;
}
