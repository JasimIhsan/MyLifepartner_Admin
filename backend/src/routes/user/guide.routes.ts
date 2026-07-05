import { Router } from "express";
import { guideController } from "@/composer/composer";

const router = Router();

/**
 * @route   GET /api/v1/user/guide
 * @desc    Get all active guides
 * @access  Private
 */
router.get("/", guideController.getGuides);

/**
 * @route   GET /api/v1/user/guide/:id
 * @desc    Get details of a guide by ID
 * @access  Private
 */
router.get("/:id", guideController.getGuideById);

export default router;
