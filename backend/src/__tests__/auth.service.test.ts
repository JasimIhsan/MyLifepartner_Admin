import { AuthService } from "@/services/user/user.auth.service";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS, HTTP_STATUS, RATE_LIMIT_CONFIG } from "@/utils/constants";
import bcrypt from "bcrypt";

// ─── Mocks ───────────────────────────────────────────────────────────────────

jest.mock("bcrypt", () => ({
   compare: jest.fn(),
   hash: jest.fn(),
}));

jest.mock("@/utils/logger", () => ({
   __esModule: true,
   default: { error: jest.fn(), info: jest.fn(), warn: jest.fn() },
}));

// Mock repositories and services
const mockUserRepo = {
   findByEmail: jest.fn(),
   create: jest.fn(),
   update: jest.fn(),
};

const mockOtpService = {
   sendOtp: jest.fn(),
   verifyOtp: jest.fn(),
   resendOtp: jest.fn(),
};

const mockJwtService = {
   signAccess: jest.fn(),
   signRefresh: jest.fn(),
   verifyRefresh: jest.fn(),
};

const mockCacheService = {
   getCache: jest.fn(),
   setCache: jest.fn(),
   deleteCache: jest.fn(),
   incrCache: jest.fn(),
   expireCache: jest.fn(),
};

const mockSubPlanRepo = {
   getPlanByName: jest.fn(),
};

const mockUserSubRepo = {
   createUserSubscription: jest.fn(),
};

const mockEmailService = {
   sendWelcomeEmail: jest.fn(),
};

// ─── Test Setup ──────────────────────────────────────────────────────────────

describe("AuthService", () => {
   let authService: AuthService;

   beforeEach(() => {
      jest.clearAllMocks();
      authService = new AuthService(
         mockUserRepo as any,
         mockOtpService as any,
         mockJwtService as any,
         mockCacheService as any,
         mockSubPlanRepo as any,
         mockUserSubRepo as any,
         mockEmailService as any
      );
   });

   const validEmail = "test@example.com";
   const normalizedEmail = "test@example.com";
   const ip = "127.0.0.1";
   const purpose = "auth";

   // ── initiateAuth ──────────────────────────────────────────────────────────

   describe("initiateAuth", () => {
      it("should return exists: true if user is found", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1, email: normalizedEmail });
         mockOtpService.sendOtp.mockResolvedValue("123456");

         const result = await authService.initiateAuth(validEmail, ip, purpose);

         expect(result.exists).toBe(true);
         expect(result.otp).toBe("123456");
         expect(mockUserRepo.findByEmail).toHaveBeenCalledWith(normalizedEmail);
         expect(mockOtpService.sendOtp).toHaveBeenCalledWith(normalizedEmail, ip, purpose);
      });

      it("should return exists: false if user is not found", async () => {
         mockUserRepo.findByEmail.mockResolvedValue(null);
         mockOtpService.sendOtp.mockResolvedValue("123456");

         const result = await authService.initiateAuth(" NEW@example.com ", ip, purpose);

         expect(result.exists).toBe(false);
         expect(mockUserRepo.findByEmail).toHaveBeenCalledWith("new@example.com"); // checking normalization
      });

      it("throws BAD_REQUEST if email is empty", async () => {
         await expect(authService.initiateAuth("", ip, purpose)).rejects.toThrow(ApiError);
         const err = await authService.initiateAuth("", ip, purpose).catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.BAD_REQUEST);
      });
   });

   // ── verifyOtp ─────────────────────────────────────────────────────────────

   describe("verifyOtp", () => {
      it("throws BAD_REQUEST if OTP is not provided", async () => {
         await expect(authService.verifyOtp(validEmail, "")).rejects.toThrow(ApiError);
         const err = await authService.verifyOtp(validEmail, "").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.BAD_REQUEST);
      });

      it("throws UNAUTHORIZED if OTP is invalid", async () => {
         mockOtpService.verifyOtp.mockResolvedValue({ isValid: false });

         await expect(authService.verifyOtp(validEmail, "000000")).rejects.toThrow(ApiError);
         const err = await authService.verifyOtp(validEmail, "000000").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.UNAUTHORIZED);
      });

      it("returns success if OTP is valid", async () => {
         mockOtpService.verifyOtp.mockResolvedValue({ isValid: true });

         const result = await authService.verifyOtp(validEmail, "123456");

         expect(result.isValid).toBe(true);
      });
   });

   // ── login ─────────────────────────────────────────────────────────────────

   describe("login", () => {
      beforeEach(() => {
         // Default successful state
         mockCacheService.getCache.mockImplementation(async (key) => {
            if (key === CACHE_KEYS.OTP_VERIFIED(normalizedEmail, purpose)) return "true";
            if (key === CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail)) return "0";
            return null;
         });
      });

      it("throws FORBIDDEN if OTP is not verified", async () => {
         mockCacheService.getCache.mockResolvedValue(null); // not verified
         
         await expect(authService.login(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.login(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.FORBIDDEN);
      });

      it("throws TOO_MANY_REQUESTS if account is locked", async () => {
         mockCacheService.getCache.mockImplementation(async (key) => {
            if (key === CACHE_KEYS.OTP_VERIFIED(normalizedEmail, purpose)) return "true";
            if (key === CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail)) return String(RATE_LIMIT_CONFIG.OTP_VERIFY_ATTEMPTS);
            return null;
         });

         await expect(authService.login(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.login(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.TOO_MANY_REQUESTS);
      });

      it("throws NOT_FOUND if user does not exist", async () => {
         mockUserRepo.findByEmail.mockResolvedValue(null);

         await expect(authService.login(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.login(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.NOT_FOUND);
      });

      it("throws UNAUTHORIZED if password is not set", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1, email: normalizedEmail }); // no password field

         await expect(authService.login(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.login(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.UNAUTHORIZED);
      });

      it("handles failed password attempt and throws UNAUTHORIZED", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1, email: normalizedEmail, password: "hashedPassword" });
         (bcrypt.compare as jest.Mock).mockResolvedValue(false);
         mockCacheService.getCache.mockImplementation(async (key) => {
            if (key === CACHE_KEYS.OTP_VERIFIED(normalizedEmail, purpose)) return "true";
            if (key === CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail)) return null; // First failed attempt
            return null;
         });

         await expect(authService.login(validEmail, "wrong-password")).rejects.toThrow(ApiError);
         
         const lockKey = CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail);
         expect(mockCacheService.incrCache).toHaveBeenCalledWith(lockKey);
         expect(mockCacheService.expireCache).toHaveBeenCalledWith(lockKey, RATE_LIMIT_CONFIG.LOCKOUT_DURATION);
      });

      it("successfully logs in and returns user and tokens", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ 
            id: 1, 
            email: normalizedEmail, 
            password: "hashedPassword",
            role: "USER" 
         });
         (bcrypt.compare as jest.Mock).mockResolvedValue(true);
         mockJwtService.signAccess.mockReturnValue("access-token");
         mockJwtService.signRefresh.mockReturnValue("refresh-token");

         const result = await authService.login(validEmail, "correct-password");

         expect(result.accessToken).toBe("access-token");
         expect(result.refreshToken).toBe("refresh-token");
         expect(result.user.email).toBe(normalizedEmail);
         
         // Should clear OTP and lock caches
         expect(mockCacheService.deleteCache).toHaveBeenCalledWith(CACHE_KEYS.OTP_VERIFIED(normalizedEmail, purpose));
         expect(mockCacheService.deleteCache).toHaveBeenCalledWith(CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail));
      });
   });

   // ── register ──────────────────────────────────────────────────────────────

   describe("register", () => {
      beforeEach(() => {
         mockCacheService.getCache.mockImplementation(async (key) => {
            if (key === CACHE_KEYS.OTP_VERIFIED(normalizedEmail, purpose)) return "true";
            return null;
         });
      });

      it("throws FORBIDDEN if OTP is not verified", async () => {
         mockCacheService.getCache.mockResolvedValue(null);
         await expect(authService.register(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.register(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.FORBIDDEN);
      });

      it("throws CONFLICT if user already exists", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1 });

         await expect(authService.register(validEmail, "password")).rejects.toThrow(ApiError);
         const err = await authService.register(validEmail, "password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.CONFLICT);
      });

      it("registers user, assigns free plan, sends email, and returns tokens", async () => {
         mockUserRepo.findByEmail.mockResolvedValue(null);
         (bcrypt.hash as jest.Mock).mockResolvedValue("hashedPassword");
         
         mockUserRepo.create.mockResolvedValue({ 
            id: 1, 
            email: normalizedEmail, 
            role: "USER" 
         });
         
         mockSubPlanRepo.getPlanByName.mockResolvedValue({ id: 99 });
         mockEmailService.sendWelcomeEmail.mockResolvedValue(undefined);
         mockJwtService.signAccess.mockReturnValue("access-token");
         mockJwtService.signRefresh.mockReturnValue("refresh-token");

         const result = await authService.register(validEmail, "password");

         expect(mockUserRepo.create).toHaveBeenCalledWith({ email: normalizedEmail, password: "hashedPassword" });
         expect(mockUserSubRepo.createUserSubscription).toHaveBeenCalledWith(expect.objectContaining({
            plan: { connect: { id: 99 } }
         }));
         expect(mockEmailService.sendWelcomeEmail).toHaveBeenCalledWith(normalizedEmail, "there");
         expect(result.accessToken).toBe("access-token");
      });
   });

   // ── forgotPassword ────────────────────────────────────────────────────────

   describe("forgotPassword", () => {
      const resetPurpose = "password_reset";
      beforeEach(() => {
         mockCacheService.getCache.mockImplementation(async (key) => {
            if (key === CACHE_KEYS.OTP_VERIFIED(normalizedEmail, resetPurpose)) return "true";
            return null;
         });
      });

      it("throws FORBIDDEN if OTP is not verified", async () => {
         mockCacheService.getCache.mockResolvedValue(null);
         await expect(authService.forgotPassword(validEmail, "new-password")).rejects.toThrow(ApiError);
         const err = await authService.forgotPassword(validEmail, "new-password").catch(e => e);
         expect(err.statusCode).toBe(HTTP_STATUS.FORBIDDEN);
      });

      it("throws NOT_FOUND if user does not exist", async () => {
         mockUserRepo.findByEmail.mockResolvedValue(null);

         await expect(authService.forgotPassword(validEmail, "new-password")).rejects.toThrow(ApiError);
      });

      it("updates password and clears caches", async () => {
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1, email: normalizedEmail });
         (bcrypt.hash as jest.Mock).mockResolvedValue("newHashedPassword");

         const result = await authService.forgotPassword(validEmail, "new-password");

         expect(mockUserRepo.update).toHaveBeenCalledWith(1, { password: "newHashedPassword" });
         expect(mockCacheService.deleteCache).toHaveBeenCalledWith(CACHE_KEYS.OTP_VERIFIED(normalizedEmail, resetPurpose));
         expect(mockCacheService.deleteCache).toHaveBeenCalledWith(CACHE_KEYS.ACCOUNT_LOCK(normalizedEmail));
         expect(result.message).toBe("Password updated successfully");
      });
   });

   // ── refreshToken ──────────────────────────────────────────────────────────

   describe("refreshToken", () => {
      it("throws UNAUTHORIZED if token not provided", async () => {
         await expect(authService.refreshToken("")).rejects.toThrow(ApiError);
      });

      it("throws UNAUTHORIZED if verify fails", async () => {
         mockJwtService.verifyRefresh.mockImplementation(() => { throw new Error("jwt expired"); });
         
         await expect(authService.refreshToken("bad-token")).rejects.toThrow(ApiError);
      });

      it("throws UNAUTHORIZED if payload missing email", async () => {
         mockJwtService.verifyRefresh.mockReturnValue({ id: 1 }); // no email
         
         await expect(authService.refreshToken("token")).rejects.toThrow(ApiError);
      });

      it("returns new tokens on success", async () => {
         mockJwtService.verifyRefresh.mockReturnValue({ email: normalizedEmail });
         mockUserRepo.findByEmail.mockResolvedValue({ id: 1, email: normalizedEmail, role: "USER" });
         mockJwtService.signAccess.mockReturnValue("new-access");
         mockJwtService.signRefresh.mockReturnValue("new-refresh");

         const result = await authService.refreshToken("valid-token");

         expect(result.accessToken).toBe("new-access");
         expect(result.refreshToken).toBe("new-refresh");
      });
   });

   // ── sendOtp ───────────────────────────────────────────────────────────────

   describe("sendOtp", () => {
      it("sends OTP and returns it", async () => {
         mockOtpService.sendOtp.mockResolvedValue("654321");
         const result = await authService.sendOtp(validEmail, ip, purpose);
         
         expect(result.otp).toBe("654321");
         expect(mockOtpService.sendOtp).toHaveBeenCalledWith(normalizedEmail, ip, purpose);
      });

      it("throws BAD_REQUEST if email is empty", async () => {
         await expect(authService.sendOtp("", ip, purpose)).rejects.toThrow(ApiError);
      });
   });

   // ── resendOtp ─────────────────────────────────────────────────────────────

   describe("resendOtp", () => {
      it("resends OTP and returns it", async () => {
         mockOtpService.resendOtp.mockResolvedValue("654321");
         const result = await authService.resendOtp(validEmail, ip, purpose);
         
         expect(result.otp).toBe("654321");
         expect(mockOtpService.resendOtp).toHaveBeenCalledWith(normalizedEmail, ip, purpose);
      });
   });

});
