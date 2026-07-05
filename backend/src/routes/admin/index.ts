import { Router } from "express";

import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";

import adminAuthRoutes from "@routes/admin/admin.auth.routes";
import adminFeatureRoutes from "@routes/admin/admin.feature.routes";
import adminGuideRoutes from "@routes/admin/admin.guide.routes";
import adminManagementRoutes from "@routes/admin/admin.management.routes";
import adminQuestionnaireRoutes from "@routes/admin/admin.questionnaire.routes";
import adminSubscriptionRoutes from "@routes/admin/admin.subscription.routes";
import adminUsersRoutes from "@routes/admin/admin.users.routes";
import imageAssetRoutes from "@routes/admin/image-asset.routes";

const router = Router();

/**
 * ─────────────────────────────────────────────
 * Admin Routes
 * ─────────────────────────────────────────────
 *
 * Base path:
 * /api/v1/admin
 *
 * Purpose:
 * Handles all admin panel APIs.
 */

// Public admin routes
router.use("/auth", adminAuthRoutes);

// Protected admin routes
router.use("/features", authenticateAdmin, adminFeatureRoutes);
router.use("/guides", authenticateAdmin, adminGuideRoutes);
router.use("/management", authenticateAdmin, adminManagementRoutes);
router.use("/questionnaires", authenticateAdmin, adminQuestionnaireRoutes);
router.use("/subscriptions", authenticateAdmin, adminSubscriptionRoutes);
router.use("/users", authenticateAdmin, adminUsersRoutes);
router.use("/image-assets", authenticateAdmin, imageAssetRoutes);

export default router;
