import { oauthController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   POST /api/v1/user/oauth/google
 * @desc    Authenticate with Google
 * @access  Public
 */
router.post("/google", oauthController.googleSignIn);

export default router;
