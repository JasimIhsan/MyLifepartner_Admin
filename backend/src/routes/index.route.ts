import adminRoutes from "@routes/admin/index";
import userRoutes from "@routes/user/index";
import deviceTokenRoutes from "./deviceToken.route";
import { Router } from "express";

const router = Router();

/**
 * ─────────────────────────────────────────────
 * Application Routes
 * ─────────────────────────────────────────────
 *
 * Central route registry for the application.
 *
 * Base route groups:
 * - /user  → User mobile app APIs
 * - /admin → Admin panel APIs
 */
router.use("/user", userRoutes);
router.use("/admin", adminRoutes);
router.use("/device-tokens", deviceTokenRoutes);

export default router;
