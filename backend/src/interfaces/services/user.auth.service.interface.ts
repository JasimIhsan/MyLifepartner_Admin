import { UserDto } from "@/dtos/user.dto";

export interface CountryDetectionResult {
   country: string;
   countryCode: string;
   callingCode: string;
   message: string;
}

export interface IUserAuthService {
   login(mobileNumber: string, otp: string): Promise<{ user: UserDto; accessToken: string; refreshToken: string }>;
   sendOtp(mobileNumber: string, sendOption: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   resendOtp(mobileNumber: string, sendOption: string): Promise<{ otp: import("@/dtos/auth.dto").OtpResponseDto }>;
   detectCountryAsync(ip: string | undefined, countryCodeHeader: string | undefined): Promise<CountryDetectionResult>;
   refreshToken(refreshToken: string): Promise<{ accessToken: string; refreshToken: string }>;
   sendMagicLink(userId: number | undefined, email: string): Promise<void>;
   verifyEmail(token: string | undefined | null): Promise<{ verified: boolean; message: string }>;
}
