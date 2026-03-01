import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";
import adminAuthRoute from "@/routes/admin/admin.auth.route";
import userAuthRoute from "@/routes/user/user.auth.route";
import profileRoute from "@/routes/user/user.profile.routes";
import userRoute from "@/routes/user/user.route";
import { Router } from "express";
import adminQuestionnaireRoute from "./admin/admin.questionnaire.route";
import adminUsersRoute from "./admin/admin.users.route";

const router = Router();

router.use("/user", userRoute);
router.use("/user/auth", userAuthRoute);
router.use("/user/profile", profileRoute);

router.use("/admin/auth", adminAuthRoute);
router.use("/admin/users", authenticateAdmin, adminUsersRoute);
router.use("/admin/questionnaire", authenticateAdmin, adminQuestionnaireRoute);

export default router;
