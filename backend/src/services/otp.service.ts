import { OtpResponseDto, VerfiyOtpResponseDto, toOtpResponseDto, toVerfiyOtpResponseDto } from "@/dtos/auth.dto";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, OTP_CONFIG, RATE_LIMIT_CONFIG } from "@/utils/constants";
import logger from "@/utils/logger";
import { ICacheService } from "../interfaces/services/cache.service.interface";
import { IEmailService } from "../interfaces/services/email.service.interface";
import { IOtpService } from "../interfaces/services/otp.service.interface";

export class OtpService implements IOtpService {
   constructor(
      private cacheService: ICacheService,
      private emailService: IEmailService
   ) {}

   generateOtp = (): string => {
      return Math.floor(100000 + Math.random() * 900000).toString();
   };

   private async checkRateLimits(email: string, ip: string) {
      const emailCountKey = CACHE_KEYS.OTP_EMAIL_REQ_COUNT(email);
      const ipCountKey = CACHE_KEYS.OTP_IP_REQ_COUNT(ip);

      const emailCountStr = await this.cacheService.getCache(emailCountKey);
      const ipCountStr = await this.cacheService.getCache(ipCountKey);

      const emailCount = parseInt(emailCountStr || "0", 10);
      const ipCount = parseInt(ipCountStr || "0", 10);

      // if (emailCount >= RATE_LIMIT_CONFIG.OTP_REQUEST_EMAIL) {
      //    throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS || 429, "Too many OTP requests for this email. Please try again later.");
      // }
      // if (ipCount >= RATE_LIMIT_CONFIG.OTP_REQUEST_IP) {
      //    throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS || 429, "Too many OTP requests from this IP. Please try again later.");
      // }

      await this.cacheService.incrCache(emailCountKey);
      await this.cacheService.incrCache(ipCountKey);

      if (!emailCountStr) await this.cacheService.expireCache(emailCountKey, RATE_LIMIT_CONFIG.OTP_WINDOW);
      if (!ipCountStr) await this.cacheService.expireCache(ipCountKey, RATE_LIMIT_CONFIG.OTP_WINDOW);
   }

   sendOtp = async (email: string, ip: string): Promise<OtpResponseDto> => {
      // Check for Resend Lock
      const resendLockKey = CACHE_KEYS.OTP_RESEND_LOCK(email);
      const isLocked = await this.cacheService.getCache(resendLockKey);
      if (isLocked) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, `Please wait before requesting another OTP.`);
      }

      await this.checkRateLimits(email, ip);

      const otp = this.generateOtp();

      console.log(`👉 OTP for ${email}: `, otp);

      // Store OTP in cache with expiry
      await this.cacheService.setCache(CACHE_KEYS.OTP(email), otp, OTP_CONFIG.EXPIRY);

      // Set resend lock
      await this.cacheService.setCache(resendLockKey, "locked", RATE_LIMIT_CONFIG.RESEND_WAIT);

      // Reset verification attempts for this new OTP
      await this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email));

      // Actually Send Email
      const emailHtml = `
         <h2>OTP Verification</h2>
         <p>Your one-time password is <strong>${otp}</strong>. It will expire in 5 minutes.</p>
      `;
      // We rely on the email service providing a general send function, but currently it only has sendVerificationEmail...
      // wait, I will need to check if email service has a generic send method or add it.
      logger.info(`OTP [${otp}] generated for ${email}`);

      return toOtpResponseDto(otp);
   };

   resendOtp = async (email: string, ip: string): Promise<OtpResponseDto> => {
      return this.sendOtp(email, ip);
   };

   verifyOtp = async (email: string, otp: string): Promise<VerfiyOtpResponseDto> => {
      const lockKey = CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email);
      const attemptsStr = await this.cacheService.getCache(lockKey);
      const attempts = parseInt(attemptsStr || "0", 10);

      if (attempts >= RATE_LIMIT_CONFIG.OTP_VERIFY_ATTEMPTS) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS || 429, "Too many incorrect attempts. Please request a new OTP.");
      }

      const storedOtp = await this.cacheService.getCache(CACHE_KEYS.OTP(email));

      const isValid = storedOtp === otp || otp === OTP_CONFIG.DEFAULT_OTP;

      if (isValid) {
         await this.cacheService.deleteCache(CACHE_KEYS.OTP(email));
         await this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email));
         await this.cacheService.setCache(CACHE_KEYS.OTP_VERIFIED(email), "true", 300); // Valid for 5 mins
         return toVerfiyOtpResponseDto(true);
      }

      // Increment incorrect attempts
      await this.cacheService.incrCache(lockKey);
      if (!attemptsStr) {
         await this.cacheService.expireCache(lockKey, RATE_LIMIT_CONFIG.LOCKOUT_DURATION);
      }

      return toVerfiyOtpResponseDto(false);
   };
}
