import { Router } from "express";
import { guideController } from "@/composer/composer";

const router = Router();

router.get("/", guideController.adminGetGuides);
router.get("/:id", guideController.getGuideById);
router.post("/", guideController.createGuide);
router.put("/:id", guideController.updateGuide);
router.delete("/:id", guideController.deleteGuide);

export default router;
