import { OtpResponseDto, VerfiyOtpResponseDto, toOtpResponseDto, toVerfiyOtpResponseDto } from "@/dtos/auth.dto";
import { CACHE_KEYS, OTP_CONFIG } from "@/utils/constants";
import logger from "@/utils/logger";
import { ICacheService } from "../interfaces/services/cache.service.interface";
import { IOtpService } from "../interfaces/services/otp.service.interface";

export class OtpService implements IOtpService {
   constructor(private cacheService: ICacheService) {}

   generateOtp = (): string => {
      // 6-digit random number
      return Math.floor(100000 + Math.random() * 900000).toString();
   };

   sendOtp = async (mobileNumber: string, sendOption: string): Promise<OtpResponseDto> => {
      const otp = this.generateOtp();

      console.log(`👉 OTP : `, otp);

      // Store OTP in cache with expiry
      await this.cacheService.setCache(CACHE_KEYS.OTP(mobileNumber), otp, OTP_CONFIG.EXPIRY);

      // TODO: Integrate actual SMS/WhatsApp Gateway
      logger.info(`OTP [${otp}] generated for ${mobileNumber} via ${sendOption}`);

      return toOtpResponseDto(otp);
   };

   resendOtp = async (mobileNumber: string, sendOption: string): Promise<OtpResponseDto> => {
      // For resend, we might want to invalidate the old one or just overwrite it.
      // Overwriting is simpler and handles "resend" effectively.
      return this.sendOtp(mobileNumber, sendOption);
   };

   verifyOtp = async (mobileNumber: string, otp: string): Promise<VerfiyOtpResponseDto> => {
      const storedOtp = await this.cacheService.getCache(CACHE_KEYS.OTP(mobileNumber));

      // Allow default logic for development or exact match
      const isValid = storedOtp === otp || otp === OTP_CONFIG.DEFAULT_OTP;

      if (isValid) {
         await this.cacheService.deleteCache(CACHE_KEYS.OTP(mobileNumber));
         return toVerfiyOtpResponseDto(true);
      }

      return toVerfiyOtpResponseDto(false);
   };
}
