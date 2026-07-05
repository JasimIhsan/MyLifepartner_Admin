import { adminFeatureController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/admin/features
 * @desc    Get all features
 * @access  Admin
 */
router.get("/", adminFeatureController.getAllFeatures);

export default router;
