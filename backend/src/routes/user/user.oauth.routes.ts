import { oauthController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   POST /api/v1/user/oauth/google
 * @desc    Authenticate with Google
 * @access  Public
 */
router.post("/google", oauthController.googleSignIn);

/**
 * @route   POST /api/v1/user/oauth/apple
 * @desc    Authenticate with Apple
 * @access  Public
 */
router.post("/apple", oauthController.appleSignIn);

/**
 * @route   POST /api/v1/user/oauth/apple/callback
 * @desc    Apple Sign In Web/Android Callback
 * @access  Public
 */
router.post("/apple/callback", oauthController.appleCallback);
router.get("/apple/callback", oauthController.appleCallback);

export default router;
