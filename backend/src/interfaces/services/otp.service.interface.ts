import { OtpResponseDto, VerfiyOtpResponseDto } from "@/dtos/auth.dto";

export interface IOtpService {
   generateOtp(): string;
   sendOtp(email: string, ip: string, purpose: string): Promise<OtpResponseDto>;
   resendOtp(email: string, ip: string, purpose: string): Promise<OtpResponseDto>;
   verifyOtp(email: string, otp: string, purpose: string): Promise<VerfiyOtpResponseDto>;
}
