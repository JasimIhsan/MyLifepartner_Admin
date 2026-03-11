import { authController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.post("/initiate", authController.initiateAuth);
router.post("/verify-otp", authController.verifyOtp);
router.post("/login", authController.login);
router.post("/register", authController.register);
router.post("/forgot-password", authController.forgotPassword); // Legacy OTP reset

// Magic Link Password Reset
router.post("/forgot-password/send-link", authController.sendPasswordResetLink);
router.get("/forgot-password/reset", authController.renderPasswordResetPage);
router.post("/forgot-password/reset", authController.resetPasswordWithLink);

router.post("/send-otp", authController.sendOtp);
router.post("/resend-otp", authController.resendOtp);

router.post("/refresh-token", authController.refreshToken);
router.get("/detect-country", authController.detectCountry);

// Magic Link Email Verification
router.post("/send-magic-link", verifyJWT, authController.sendMagicLink);
router.post("/verify-email", authController.verifyEmailLink);
router.get("/verify-email", authController.verifyEmailPage);

export default router;
