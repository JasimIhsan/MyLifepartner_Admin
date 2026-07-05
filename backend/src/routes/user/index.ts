import { Router } from "express";

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
 * Purpose:
 * Handles all user-side mobile app APIs.
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
