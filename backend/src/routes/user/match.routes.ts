import { matchController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

// Apply auth middleware to all match routes
router.use(verifyJWT);

router.get("/recommendations", matchController.getRecommendations);
router.post("/swipe", matchController.swipeProfile);

export default router;
