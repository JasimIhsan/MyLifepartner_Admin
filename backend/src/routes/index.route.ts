import adminRoute from "@/routes/admin/auth.route";
import profileRoute from "@/routes/profile.routes";
import userAuthRoute from "@/routes/user/user.auth.route";
import userRoute from "@/routes/user/user.route";
import { Router } from "express";

const router = Router();

router.use("/user", userRoute);
router.use("/user/auth", userAuthRoute);
router.use("/user/profile", profileRoute);

router.use("/admin", adminRoute);

export default router;
