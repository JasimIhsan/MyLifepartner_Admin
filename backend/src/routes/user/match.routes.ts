import { matchController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

// Apply auth middleware to all match routes
router.use(verifyJWT);

router.get("/recommendations", matchController.getRecommendations);
router.get("/interests/sent", matchController.getSentInterests);
router.get("/interests/received", matchController.getReceivedInterests);
router.get("/mutual-matches", matchController.getMutualMatches);
router.get("/profile/:profileId", matchController.getProfileDetail);
router.post("/swipe", matchController.swipeProfile);

export default router;
