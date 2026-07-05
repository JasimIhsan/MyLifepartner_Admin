import { zegoController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   GET /api/v1/user/zego/token
 * @desc    Get Zego token for initiating/joining calls
 * @access  Private
 */
router.get("/token", zegoController.getToken);

export default router;
