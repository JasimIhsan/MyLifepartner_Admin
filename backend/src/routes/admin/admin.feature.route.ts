import { Router } from "express";
import { adminFeatureController } from "@/composer/composer";

const router = Router();

router.post("/", adminFeatureController.createFeature);
router.get("/", adminFeatureController.getAllFeatures);
router.get("/:id", adminFeatureController.getFeatureById);
router.patch("/:id", adminFeatureController.updateFeature);
router.delete("/:id", adminFeatureController.deleteFeature);

export default router;
