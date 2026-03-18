import { UserDto } from "@/dtos/user.dto";

export interface IUserAuthService {
   initiateAuth(email: string, ip: string, purpose: string): Promise<{ exists: boolean; otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   verifyOtp(email: string, otp: string, purpose: string): Promise<{ isValid: boolean; message: string }>;
   login(email: string, passwordPlain: string): Promise<{ user: UserDto; accessToken: string; refreshToken: string }>;
   register(email: string, passwordPlain: string): Promise<{ user: UserDto; accessToken: string; refreshToken: string }>;
   forgotPassword(email: string, passwordPlain: string): Promise<{ message: string }>;
   sendOtp(email: string, ip: string, purpose: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   resendOtp(email: string, ip: string, purpose: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }>;
}
