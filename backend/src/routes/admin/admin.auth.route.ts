import { Router } from "express";
import adminAuthController from "../../controllers/admin/admin.auth.controller";

const adminAuthRoute = Router();

adminAuthRoute.post("/login", adminAuthController.login);
adminAuthRoute.post("/refresh", adminAuthController.refresh);
adminAuthRoute.post("/logout", adminAuthController.logout);

export default adminAuthRoute;
