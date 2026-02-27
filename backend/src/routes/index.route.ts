import adminAuthRoute from "@/routes/admin/admin.auth.route";
import userAuthRoute from "@/routes/user/user.auth.route";
import profileRoute from "@/routes/user/user.profile.routes";
import userRoute from "@/routes/user/user.route";
import { Router } from "express";

const router = Router();

router.use("/user", userRoute);
router.use("/user/auth", userAuthRoute);
router.use("/user/profile", profileRoute);

router.use("/admin/auth", adminAuthRoute);

export default router;
