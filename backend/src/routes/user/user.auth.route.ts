import authController from "@/controllers/user/auth.controller";
import { Router } from "express";

const router = Router();

router.post("/send-otp", authController.sendOtp);
router.post("/resend-otp", authController.resendOtp);
router.post("/login", authController.login);
router.get("/detect-country", authController.detectCountry);

export default router;
