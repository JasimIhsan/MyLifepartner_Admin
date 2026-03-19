import { authController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.post("/initiate", authController.initiateAuth);
router.post("/verify-otp", authController.verifyOtp);
router.post("/login", authController.login);
router.post("/register", authController.register);
router.post("/forgot-password", authController.forgotPassword); // Legacy OTP reset



router.post("/send-otp", authController.sendOtp);
router.post("/resend-otp", authController.resendOtp);

router.post("/refresh-token", authController.refreshToken);
router.get("/me", verifyJWT, authController.me);




export default router;
