import cacheService from "@/services/cache.service";
import { CACHE_KEYS, OTP_CONFIG } from "@/utils/constants";
import logger from "@/utils/logger";

class OtpService {
   generateOtp = (): string => {
      // 6-digit random number
      return Math.floor(100000 + Math.random() * 900000).toString();
   };

   sendOtp = async (mobileNumber: string, sendOption: string) => {
      const otp = this.generateOtp();

      // Store OTP in cache with expiry
      await cacheService.setCache(CACHE_KEYS.OTP(mobileNumber), otp, OTP_CONFIG.EXPIRY);

      // TODO: Integrate actual SMS/WhatsApp Gateway
      logger.info(`OTP [${otp}] generated for ${mobileNumber} via ${sendOption}`);

      return otp;
   };

   verifyOtp = async (mobileNumber: string, otp: string): Promise<boolean> => {
      const storedOtp = await cacheService.getCache(CACHE_KEYS.OTP(mobileNumber));

      // Allow default logic for development or exact match
      const isValid = storedOtp === otp || otp === OTP_CONFIG.DEFAULT_OTP;

      if (isValid) {
         await cacheService.deleteCache(CACHE_KEYS.OTP(mobileNumber));
         return true;
      }

      return false;
   };
}

export default new OtpService();
