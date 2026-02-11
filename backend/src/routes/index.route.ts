import { Router } from "express";
import adminRoute from "./admin/auth.route";
import userRoute from "./user/user.route";

const router = Router();

router.use("/users", userRoute);
router.use("/admin", adminRoute);

export default router;
