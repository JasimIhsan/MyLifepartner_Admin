import { zegoController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   GET /api/v1/user/zego/token
 * @desc    Issue a ZEGOCLOUD token (used on login / call start)
 * @access  Private
 */
router.get("/token", zegoController.getToken);

/**
 * @route   POST /api/v1/user/zego/renew-token
 * @desc    Renew a ZEGOCLOUD token mid-session (called before expiry)
 * @access  Private
 */
router.post("/renew-token", zegoController.renewToken);

export default router;
