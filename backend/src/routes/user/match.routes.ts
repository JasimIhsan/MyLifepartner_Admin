import { matchController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

// Apply auth middleware to all match routes
router.use(verifyJWT);

/**
 * @route   GET /api/v1/user/match/recommendations
 * @desc    Get recommended matches/profiles for current user
 * @access  Private
 */
router.get("/recommendations", matchController.getRecommendations);

/**
 * @route   GET /api/v1/user/match/interests/sent
 * @desc    Get sent swiped profiles/interests
 * @access  Private
 */
router.get("/interests/sent", matchController.getSentInterests);

/**
 * @route   GET /api/v1/user/match/interests/received
 * @desc    Get profiles that showed interest in current user
 * @access  Private
 */
router.get("/interests/received", matchController.getReceivedInterests);

/**
 * @route   GET /api/v1/user/match/mutual-matches
 * @desc    Get matched profiles (mutual interest)
 * @access  Private
 */
router.get("/mutual-match", matchController.getMutualMatches);

/**
 * @route   GET /api/v1/user/match/profile/:profileId
 * @desc    Get match candidate profile details by ID
 * @access  Private
 */
router.get("/profile/:profileId", matchController.getProfileDetail);

/**
 * @route   POST /api/v1/user/match/swipe
 * @desc    Swipe profile (like, pass, superlike)
 * @access  Private
 */
router.post("/swipe", matchController.swipeProfile);

/**
 * @route   POST /api/v1/user/match/swipe/cancel
 * @desc    Cancel sent interest swipe
 * @access  Private
 */
router.post("/swipe/cancel", matchController.cancelSwipeInterest);

export default router;
