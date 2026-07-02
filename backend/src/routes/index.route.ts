import { adminSubscriptionController, imageAssetController } from "@/composer/composer";
import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";
import adminAuthRoute from "@/routes/admin/admin.auth.route";
import adminGuideRoute from "@/routes/admin/admin.guide.routes";
import chatRoute from "@/routes/user/chat.routes";
import userGuideRoute from "@/routes/user/guide.routes";
import matchRoute from "@/routes/user/match.routes";
import userAuthRoute from "@/routes/user/user.auth.route";
import profileRoute from "@/routes/user/user.profile.routes";
import userRoute from "@/routes/user/user.route";
import userSubscriptionRoute from "@/routes/user/user.subscription.routes";
import zegoRoute from "@/routes/user/zego.routes";
import { Router } from "express";
import adminFeatureRoute from "./admin/admin.feature.route";
import adminManagementRoute from "./admin/admin.management.route";
import adminQuestionnaireRoute from "./admin/admin.questionnaire.route";
import adminSubscriptionRoute from "./admin/admin.subscription.route";
import adminUsersRoute from "./admin/admin.users.route";
import imageAssetRoute from "./admin/image-asset.route";

const router = Router();

router.use("/user/auth", userAuthRoute);
router.use("/user/profile", profileRoute);
router.use("/user/subscriptions", userSubscriptionRoute);
router.use("/user/guides", userGuideRoute);
router.use("/user", userRoute);
router.use("/matches", matchRoute);

router.use("/chat", chatRoute);

router.use("/zego", zegoRoute);

router.use("/admin/auth", adminAuthRoute);
router.use("/admin/users", authenticateAdmin, adminUsersRoute);
router.use("/admin/questionnaire", authenticateAdmin, adminQuestionnaireRoute);
router.use("/admin/managers", adminManagementRoute); // verifyJWT & isSuperAdmin are inside the route

router.use("/admin/guides", authenticateAdmin, adminGuideRoute);

// ── Subscription Management ────────────────────────────────────────────────
router.use("/admin/features", authenticateAdmin, adminFeatureRoute);

// Plan routes
router.use("/admin/plans", authenticateAdmin, adminSubscriptionRoute);

// Feature mapping mutations on plans
router.patch("/admin/plans/:planId/features/:featureId", authenticateAdmin, adminSubscriptionController.updatePlanFeature);
router.delete("/admin/plans/:planId/features/:featureId", authenticateAdmin, adminSubscriptionController.deletePlanFeature);

// ── Image Assets Management ────────────────────────────────────────────────
router.use("/admin/image-assets", authenticateAdmin, imageAssetRoute);

// Public Image Assets
router.get("/user/image-assets/:section", imageAssetController.getAssetsBySection);

export default router;
