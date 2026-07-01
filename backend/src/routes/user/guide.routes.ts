import { Router } from "express";
import { guideController } from "@/composer/composer";

const router = Router();

router.get("/", guideController.getGuides);

export default router;
