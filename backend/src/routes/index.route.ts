import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";
import adminAuthRoute from "@/routes/admin/admin.auth.route";
import matchRoute from "@/routes/user/match.routes";
import userAuthRoute from "@/routes/user/user.auth.route";
import profileRoute from "@/routes/user/user.profile.routes";
import userRoute from "@/routes/user/user.route";
import { Router } from "express";
import adminManagementRoute from "./admin/admin.management.route";
import adminQuestionnaireRoute from "./admin/admin.questionnaire.route";
import adminSubscriptionRoute from "./admin/admin.subscription.route";
import adminUsersRoute from "./admin/admin.users.route";
import { adminSubscriptionController } from "@/composer/composer";

const router = Router();

router.use("/user", userRoute);
router.use("/user/auth", userAuthRoute);
router.use("/user/profile", profileRoute);
router.use("/matches", matchRoute);

router.use("/admin/auth", adminAuthRoute);
router.use("/admin/users", authenticateAdmin, adminUsersRoute);
router.use("/admin/questionnaire", authenticateAdmin, adminQuestionnaireRoute);
router.use("/admin/managers", adminManagementRoute); // verifyJWT & isSuperAdmin are inside the route

// ── Subscription Management ────────────────────────────────────────────────
import adminFeatureRoute from "./admin/admin.feature.route";
router.use("/admin/features", authenticateAdmin, adminFeatureRoute);

// Plan routes
router.use("/admin/plans", authenticateAdmin, adminSubscriptionRoute);

// Feature mapping mutations on plans
router.patch("/admin/plans/:planId/features/:featureId", authenticateAdmin, adminSubscriptionController.updatePlanFeature);
router.delete("/admin/plans/:planId/features/:featureId", authenticateAdmin, adminSubscriptionController.deletePlanFeature);

export default router;

