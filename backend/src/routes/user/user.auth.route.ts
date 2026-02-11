import authController from "@/controllers/user/auth.controller";
import { Router } from "express";

const router = Router();

router.post("/send-otp", authController.sendOtp);
router.post("/login", authController.login);

export default router;
