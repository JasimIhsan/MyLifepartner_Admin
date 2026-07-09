import { imageAssetController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/user/image-assets/:section
 * @desc    Get image assets by section
 * @access  Public
 */
router.get("/:section", imageAssetController.getAssetsBySection);

export default router;
