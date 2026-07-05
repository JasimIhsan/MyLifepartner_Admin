import { Router } from "express";

// User Route Modules
import chatRoutes from "@routes/user/chat.routes";
import guideRoutes from "@routes/user/guide.routes";
import matchRoutes from "@routes/user/match.routes";
import userAuthRoutes from "@routes/user/user.auth.routes";
import userProfileRoutes from "@routes/user/user.profile.routes";
import userRoutes from "@routes/user/user.routes";
import userSubscriptionRoutes from "@routes/user/user.subscription.routes";
import zegoRoutes from "@routes/user/zego.routes";

const router = Router();

/**
 * ─────────────────────────────────────────────
 * User Routes
 * ─────────────────────────────────────────────
 *
 * Base path:
 * /api/v1/user
 *
 * Registered routes:
 * - /auth          → Login, register, OTP, token APIs
 * - /profile       → User profile APIs
 * - /subscription  → User subscription APIs
 * - /chat          → Chat APIs
 * - /guide         → User guide/content APIs
 * - /match         → Matching APIs
 * - /zego          → Zego call/chat integration APIs
 * - /              → General user APIs
 */
router.use("/auth", userAuthRoutes);
router.use("/profile", userProfileRoutes);
router.use("/subscription", userSubscriptionRoutes);
router.use("/chat", chatRoutes);
router.use("/guide", guideRoutes);
router.use("/match", matchRoutes);
router.use("/zego", zegoRoutes);
router.use("/", userRoutes);

export default router;
