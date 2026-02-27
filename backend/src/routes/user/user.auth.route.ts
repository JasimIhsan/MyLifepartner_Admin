import authController from "@/controllers/user/auth.controller";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.post("/send-otp", authController.sendOtp);
router.post("/resend-otp", authController.resendOtp);
router.post("/login", authController.login);
router.post("/refresh-token", authController.refreshToken);
router.get("/detect-country", authController.detectCountry);

// Magic Link Email Verification
router.post("/send-magic-link", verifyJWT, authController.sendMagicLink);
router.post("/verify-email", authController.verifyEmail);
router.get("/verify-email", authController.verifyEmailPage);

export default router;
