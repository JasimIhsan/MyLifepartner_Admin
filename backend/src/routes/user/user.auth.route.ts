import { authController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { authLimiter } from "@/middlewares/rateLimiter.middleware";
import { Router } from "express";

const router = Router();

router.post("/initiate", authLimiter, authController.initiateAuth);
router.post("/verify-otp", authLimiter, authController.verifyOtp);
router.post("/login", authLimiter, authController.login);
router.post("/register", authLimiter, authController.register);
router.post("/forgot-password", authLimiter, authController.forgotPassword); // Legacy OTP reset



router.post("/send-otp", authLimiter, authController.sendOtp);
router.post("/resend-otp", authLimiter, authController.resendOtp);

router.post("/refresh-token", authController.refreshToken);
router.get("/me", verifyJWT, authController.me);




export default router;
