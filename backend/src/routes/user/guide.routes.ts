import { Router } from "express";
import { guideController } from "@/composer/composer";

const router = Router();

router.get("/", guideController.getGuides);
router.get("/:id", guideController.getGuideById);

export default router;
