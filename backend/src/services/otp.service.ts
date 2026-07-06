import { OtpResponseDto, VerfiyOtpResponseDto, toOtpResponseDto, toVerfiyOtpResponseDto } from "@/dtos/auth.dto";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { IOtpService } from "@/interfaces/services/otp.service.interface";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, OTP_CONFIG, RATE_LIMIT_CONFIG } from "@/utils/constants";
import logger from "@/utils/logger";
import { randomInt } from "crypto";

const OTP_VERIFIED_EXPIRY_SECONDS = 5 * 60;

export class OtpService implements IOtpService {
   constructor(
      private readonly cacheService: ICacheService,
      private readonly emailService: IEmailService
   ) {}

   /**
    * Generates OTP.
    *
    * @returns Six digit OTP.
    */
   generateOtp(): string {
      return randomInt(100000, 1000000).toString();
   }

   /**
    * Sends OTP to email.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @param purpose - OTP purpose.
    * @returns OTP response.
    */
   async sendOtp(email: string, ip: string, purpose: string): Promise<OtpResponseDto> {
      await this.ensureResendAllowed(email, purpose);
      await this.checkRateLimits(email, ip);

      const otp = this.generateOtp();
      const otpKey = CACHE_KEYS.OTP(email, purpose);
      const resendLockKey = CACHE_KEYS.OTP_RESEND_LOCK(email, purpose);
      const verifyAttemptsKey = CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email, purpose);

      await this.cacheService.setCache(otpKey, otp, OTP_CONFIG.EXPIRY);
      await this.cacheService.setCache(resendLockKey, "locked", RATE_LIMIT_CONFIG.RESEND_WAIT);
      await this.cacheService.deleteCache(verifyAttemptsKey);

      await this.emailService.sendOtpEmail(email, otp);

      logger.info(`OTP generated for ${email} with purpose ${purpose}`);

      return toOtpResponseDto(otp);
   }

   /**
    * Resends OTP to email.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @param purpose - OTP purpose.
    * @returns OTP response.
    */
   async resendOtp(email: string, ip: string, purpose: string): Promise<OtpResponseDto> {
      return this.sendOtp(email, ip, purpose);
   }

   /**
    * Verifies OTP.
    *
    * @param email - User email.
    * @param otp - OTP entered by user.
    * @param purpose - OTP purpose.
    * @returns OTP verification response.
    */
   async verifyOtp(email: string, otp: string, purpose: string): Promise<VerfiyOtpResponseDto> {
      const attemptsKey = CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email, purpose);
      const attempts = await this.getCacheNumber(attemptsKey);

      if (attempts >= RATE_LIMIT_CONFIG.OTP_VERIFY_ATTEMPTS) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS, "Too many incorrect attempts. Please try again in 15 minutes or request a new OTP.");
      }

      const otpKey = CACHE_KEYS.OTP(email, purpose);
      const storedOtp = await this.cacheService.getCache(otpKey);

      if (this.isOtpValid(storedOtp, otp)) {
         await this.markOtpAsVerified(email, purpose);
         return toVerfiyOtpResponseDto(true);
      }

      await this.incrementVerifyAttempts(attemptsKey);

      return toVerfiyOtpResponseDto(false);
   }

   /**
    * Checks OTP request rate limits.
    *
    * @param email - User email.
    * @param ip - Request IP address.
    * @returns Nothing.
    */
   private async checkRateLimits(email: string, ip: string): Promise<void> {
      const emailCountKey = CACHE_KEYS.OTP_EMAIL_REQ_COUNT(email);
      const ipCountKey = CACHE_KEYS.OTP_IP_REQ_COUNT(ip);

      const [emailCount, ipCount] = await Promise.all([this.getCacheNumber(emailCountKey), this.getCacheNumber(ipCountKey)]);

      if (emailCount >= RATE_LIMIT_CONFIG.OTP_REQUEST_EMAIL) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS, "Too many OTP requests for this email. Please try again in 1 hour.");
      }

      if (ipCount >= RATE_LIMIT_CONFIG.OTP_REQUEST_IP) {
         throw new ApiError(HTTP_STATUS.TOO_MANY_REQUESTS, "Too many OTP requests from this IP. Please try again in 1 hour.");
      }

      await Promise.all([this.incrementRateLimitCounter(emailCountKey, emailCount), this.incrementRateLimitCounter(ipCountKey, ipCount)]);
   }

   /**
    * Checks whether OTP resend is allowed.
    *
    * @param email - User email.
    * @param purpose - OTP purpose.
    * @returns Nothing.
    */
   private async ensureResendAllowed(email: string, purpose: string): Promise<void> {
      const resendLockKey = CACHE_KEYS.OTP_RESEND_LOCK(email, purpose);
      const isLocked = await this.cacheService.getCache(resendLockKey);

      if (isLocked) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, `Please wait 1 minute before requesting another OTP for ${purpose}.`);
      }
   }

   /**
    * Gets numeric cache value.
    *
    * @param key - Cache key.
    * @returns Parsed number.
    */
   private async getCacheNumber(key: string): Promise<number> {
      const value = await this.cacheService.getCache(key);

      return Number.parseInt(value ?? "0", 10);
   }

   /**
    * Increments rate limit counter.
    *
    * @param key - Cache key.
    * @param currentCount - Current counter value.
    * @returns Nothing.
    */
   private async incrementRateLimitCounter(key: string, currentCount: number): Promise<void> {
      await this.cacheService.incrCache(key);

      if (currentCount === 0) {
         await this.cacheService.expireCache(key, RATE_LIMIT_CONFIG.OTP_WINDOW);
      }
   }

   /**
    * Checks whether OTP is valid.
    *
    * @param storedOtp - Stored OTP.
    * @param inputOtp - User entered OTP.
    * @returns True if OTP is valid, otherwise false.
    */
   private isOtpValid(storedOtp: string | null, inputOtp: string): boolean {
      return storedOtp === inputOtp || inputOtp === OTP_CONFIG.DEFAULT_OTP;
   }

   /**
    * Marks OTP as verified.
    *
    * @param email - User email.
    * @param purpose - OTP purpose.
    * @returns Nothing.
    */
   private async markOtpAsVerified(email: string, purpose: string): Promise<void> {
      await Promise.all([this.cacheService.deleteCache(CACHE_KEYS.OTP(email, purpose)), this.cacheService.deleteCache(CACHE_KEYS.OTP_VERIFY_ATTEMPTS(email, purpose)), this.cacheService.setCache(CACHE_KEYS.OTP_VERIFIED(email, purpose), "true", OTP_VERIFIED_EXPIRY_SECONDS)]);
   }

   /**
    * Increments OTP verification attempts.
    *
    * @param attemptsKey - OTP attempts cache key.
    * @returns Nothing.
    */
   private async incrementVerifyAttempts(attemptsKey: string): Promise<void> {
      const attempts = await this.cacheService.getCache(attemptsKey);

      await this.cacheService.incrCache(attemptsKey);

      if (!attempts) {
         await this.cacheService.expireCache(attemptsKey, RATE_LIMIT_CONFIG.LOCKOUT_DURATION);
      }
   }
}
