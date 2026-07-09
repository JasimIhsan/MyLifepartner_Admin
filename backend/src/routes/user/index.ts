import { Router } from "express";

import chatRoutes from "@routes/user/chat.routes";
import guideRoutes from "@routes/user/guide.routes";
import imageAccessRequestRoutes from "@routes/user/image-access-request.routes";
import imageAssetRoutes from "@routes/user/image-asset.routes";
import jobRoutes from "@routes/user/job.routes";
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
router.use("/jobs", jobRoutes);
router.use("/image-assets", imageAssetRoutes);
router.use("/image-access", imageAccessRequestRoutes);
router.use("/", userRoutes);

export default router;
