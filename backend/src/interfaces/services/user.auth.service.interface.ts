import { UserDto } from "@/dtos/user.dto";

export interface CountryDetectionResult {
   country: string;
   countryCode: string;
   callingCode: string;
   message: string;
}

export interface IUserAuthService {
   initiateAuth(email: string, ip: string): Promise<{ exists: boolean; otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   verifyOtp(email: string, otp: string): Promise<{ isValid: boolean; message: string }>;
   login(email: string, passwordPlain: string): Promise<{ user: UserDto; accessToken: string; refreshToken: string }>;
   register(email: string, passwordPlain: string): Promise<{ user: UserDto; accessToken: string; refreshToken: string }>;
   forgotPassword(email: string, passwordPlain: string): Promise<{ message: string }>;
   sendOtp(email: string, ip: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   resendOtp(email: string, ip: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   detectCountryAsync(ip: string | undefined, countryCodeHeader: string | undefined): Promise<CountryDetectionResult>;
   refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }>;
   sendMagicLink(userId: number | undefined, email: string): Promise<void>;
   verifyEmailLink(token: string | undefined | null): Promise<{ verified: boolean; message: string }>;
   sendPasswordResetLink(email: string): Promise<void>;
   renderPasswordResetPage(token: string | undefined | null | any): Promise<string>;
   resetPasswordWithLink(token: string | undefined | null | any, passwordPlain: string): Promise<{ success: boolean; message: string }>;
}
