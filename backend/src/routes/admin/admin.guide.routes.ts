import { Router } from "express";
import { guideController } from "@/composer/composer";

const router = Router();

/**
 * @route   GET /api/v1/admin/guides
 * @desc    Get all guides for admin panel
 * @access  Admin
 */
router.get("/", guideController.adminGetGuides);

/**
 * @route   GET /api/v1/admin/guides/categories
 * @desc    Get all guide categories
 * @access  Admin
 */
router.get("/categories", guideController.getGuideCategories);

/**
 * @route   POST /api/v1/admin/guides/categories
 * @desc    Create a new guide category
 * @access  Admin
 */
router.post("/categories", guideController.createGuideCategory);

/**
 * @route   PUT /api/v1/admin/guides/categories/:id
 * @desc    Update a guide category by ID
 * @access  Admin
 */
router.put("/categories/:id", guideController.updateGuideCategory);

/**
 * @route   DELETE /api/v1/admin/guides/categories/:id
 * @desc    Delete a guide category by ID
 * @access  Admin
 */
router.delete("/categories/:id", guideController.deleteGuideCategory);

/**
 * @route   GET /api/v1/admin/guides/:id
 * @desc    Get guide by ID
 * @access  Admin
 */
router.get("/:id", guideController.getGuideById);

/**
 * @route   POST /api/v1/admin/guides
 * @desc    Create a new guide
 * @access  Admin
 */
router.post("/", guideController.createGuide);

/**
 * @route   PUT /api/v1/admin/guides/:id
 * @desc    Update a guide by ID
 * @access  Admin
 */
router.put("/:id", guideController.updateGuide);

/**
 * @route   DELETE /api/v1/admin/guides/:id
 * @desc    Delete a guide by ID
 * @access  Admin
 */
router.delete("/:id", guideController.deleteGuide);

export default router;
