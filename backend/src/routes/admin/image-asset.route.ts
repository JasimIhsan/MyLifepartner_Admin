import { Router } from "express";
import multer from "multer";
import { imageAssetController } from "@/composer/composer";

const router = Router();
const upload = multer({ storage: multer.memoryStorage() });

// Admin Asset Management
router.get("/", imageAssetController.getAllAssets);
router.post("/", upload.single("file"), imageAssetController.createAsset);
router.put("/:id", upload.single("file"), imageAssetController.updateAsset);
router.delete("/:id", imageAssetController.deleteAsset);

export default router;
