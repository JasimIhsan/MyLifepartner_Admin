import { Router } from "express";
import multer from "multer";
import { imageAssetController } from "@/composer/composer";

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

// Admin Asset Management

/**
 * @route   GET /api/v1/admin/image-assets
 * @desc    Get all image assets
 * @access  Admin
 */
router.get("/", imageAssetController.getAllAssets);

/**
 * @route   POST /api/v1/admin/image-assets
 * @desc    Upload/create a new image asset
 * @access  Admin
 */
router.post("/", upload.single("file"), imageAssetController.createAsset);

/**
 * @route   PUT /api/v1/admin/image-assets/:id
 * @desc    Update an image asset by ID
 * @access  Admin
 */
router.put("/:id", upload.single("file"), imageAssetController.updateAsset);

/**
 * @route   DELETE /api/v1/admin/image-assets/:id
 * @desc    Delete an image asset by ID
 * @access  Admin
 */
router.delete("/:id", imageAssetController.deleteAsset);

export default router;
