import { adminFeatureController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

router.get("/", adminFeatureController.getAllFeatures);

export default router;
