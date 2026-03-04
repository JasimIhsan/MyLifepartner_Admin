import { Router } from "express";
import adminAuthController from "../../controllers/admin/admin.auth.controller";
import { verifyJWT } from "../../middlewares/auth.middleware";

const adminAuthRoute = Router();

adminAuthRoute.get("/me", verifyJWT, adminAuthController.getMe);
adminAuthRoute.post("/login", adminAuthController.login);
adminAuthRoute.post("/refresh", adminAuthController.refresh);
adminAuthRoute.post("/logout", verifyJWT, adminAuthController.logout);

export default adminAuthRoute;
