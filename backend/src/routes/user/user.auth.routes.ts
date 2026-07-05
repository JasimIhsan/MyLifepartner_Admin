import { authController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

/**
 * @route   POST /api/v1/user/auth/initiate
 * @desc    Initiate OTP authentication flow (send OTP to phone)
 * @access  Public
 */
router.post("/initiate", authController.initiateAuth);

/**
 * @route   POST /api/v1/user/auth/verify-otp
 * @desc    Verify OTP for authentication
 * @access  Public
 */
router.post("/verify-otp", authController.verifyOtp);

/**
 * @route   POST /api/v1/user/auth/login
 * @desc    Log in user with password or verify login
 * @access  Public
 */
router.post("/login", authController.login);

/**
 * @route   POST /api/v1/user/auth/register
 * @desc    Register a new user
 * @access  Public
 */
router.post("/register", authController.register);

/**
 * @route   POST /api/v1/user/auth/forgot-password
 * @desc    Initiate password reset (Legacy OTP reset)
 * @access  Public
 */
router.post("/forgot-password", authController.forgotPassword);

/**
 * @route   POST /api/v1/user/auth/send-otp
 * @desc    Send general OTP
 * @access  Public
 */
router.post("/send-otp", authController.sendOtp);

/**
 * @route   POST /api/v1/user/auth/resend-otp
 * @desc    Resend OTP to phone number
 * @access  Public
 */
router.post("/resend-otp", authController.resendOtp);

/**
 * @route   POST /api/v1/user/auth/refresh-token
 * @desc    Refresh user access token
 * @access  Public
 */
router.post("/refresh-token", authController.refreshToken);

/**
 * @route   GET /api/v1/user/auth/me
 * @desc    Get current logged in user details
 * @access  Private
 */
router.get("/me", verifyJWT, authController.me);

export default router;
