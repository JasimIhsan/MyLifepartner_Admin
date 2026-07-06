import { adminAuthController } from "@/composer/composer";
import { Router } from "express";
import { authenticateAdmin } from "../../middlewares/admin.auth.middleware";

const adminAuthRoute = Router();

/**
 * @route   GET /api/v1/admin/auth/me
 * @desc    Get current admin profile
 * @access  Private (Admin)
 */
adminAuthRoute.get("/me", authenticateAdmin, adminAuthController.getMe);

/**
 * @route   POST /api/v1/admin/auth/login
 * @desc    Admin login
 * @access  Public
 */
adminAuthRoute.post("/login", adminAuthController.login);

/**
 * @route   POST /api/v1/admin/auth/refresh
 * @desc    Refresh admin access token
 * @access  Public
 */
adminAuthRoute.post("/refresh", adminAuthController.refresh);

/**
 * @route   POST /api/v1/admin/auth/logout
 * @desc    Admin logout
 * @access  Private (Admin)
 */
adminAuthRoute.post("/logout", authenticateAdmin, adminAuthController.logout);

export default adminAuthRoute;
