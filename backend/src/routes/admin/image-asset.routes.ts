import { imageAssetController } from "@/composer/composer";
import { Router } from "express";
import multer from "multer";

const router = Router();

const upload = multer({
   storage: multer.memoryStorage(),
});

/**
 * @route GET /api/v1/admin/image-assets
 * @purpose Fetches all image assets.
 */
router.get("/", imageAssetController.getAllAssets);

/**
 * @route GET /api/v1/admin/image-assets/section/:section
 * @purpose Fetches image assets by section.
 */
router.get("/section/:section", imageAssetController.getAssetsBySection);

/**
 * @route POST /api/v1/admin/image-assets
 * @purpose Creates a new image asset.
 */
router.post("/", upload.single("file"), imageAssetController.createAsset);

/**
 * @route PUT /api/v1/admin/image-assets/:id
 * @purpose Updates an image asset by ID.
 */
router.put("/:id", upload.single("file"), imageAssetController.updateAsset);

/**
 * @route DELETE /api/v1/admin/image-assets/:id
 * @purpose Deletes an image asset by ID.
 */
router.delete("/:id", imageAssetController.deleteAsset);

export default router;
