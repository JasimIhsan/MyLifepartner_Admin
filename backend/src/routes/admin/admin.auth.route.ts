import { Router } from "express";
import adminAuthController from "../../controllers/admin/auth.controller";

const adminAuthRoute = Router();

adminAuthRoute.post("/login", adminAuthController.login);

export default adminAuthRoute;
