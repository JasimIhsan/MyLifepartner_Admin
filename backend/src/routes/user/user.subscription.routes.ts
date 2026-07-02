import { Router } from "express";
import { userSubscriptionController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";

const router = Router();

// Protect all subscription routes except webhook
router.post("/webhook", userSubscriptionController.webhook);

router.use(verifyJWT);

/**
 * @route GET /user/subscriptions/plans
 * @desc Get available subscription plans
 */
router.get("/plans", userSubscriptionController.getPlans);

/**
 * @route GET /user/subscriptions/my-subscription
 * @desc Get the current user's active subscription
 */
router.get("/my-subscription", userSubscriptionController.getMySubscription);

/**
 * @route GET /user/subscriptions/features
 * @desc Get the current user's power/features
 */
router.get("/features", userSubscriptionController.getUserFeatures);

/**
 * @route POST /user/subscriptions/subscribe
 * @desc Subscribe to a plan (mocks payment logic by activating immediately)
 */
router.post("/subscribe", userSubscriptionController.subscribe);

/**
 * @route POST /user/subscriptions/check-call
 * @desc Check if user can initiate an audio or video call
 */
router.post("/check-call", userSubscriptionController.checkCallAccess);

/**
 * @route POST /user/subscriptions/sync
 * @desc Sync active subscriptions from RevenueCat
 */
router.post("/sync", userSubscriptionController.sync);

export default router;
