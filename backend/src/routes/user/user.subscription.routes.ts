import { Router } from "express";

import { userSubscriptionController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";

const router = Router();

/**
 * ─────────────────────────────────────────────
 * Public Routes
 * ─────────────────────────────────────────────
 */

/**
 * @route POST /user/subscriptions/webhook
 * @desc RevenueCat webhook endpoint
 * @access Public
 */
router.post("/webhook", userSubscriptionController.webhook);

/**
 * ─────────────────────────────────────────────
 * Protected Routes
 * ─────────────────────────────────────────────
 */

router.use(verifyJWT);

/**
 * ─────────────────────────────────────────────
 * Subscription Read Routes
 * ─────────────────────────────────────────────
 */

/**
 * @route GET /user/subscriptions/plans
 * @desc Get available subscription plans
 * @access Private
 */
router.get("/plans", userSubscriptionController.getPlans);

/**
 * @route GET /user/subscriptions/my-subscription
 * @desc Get the current user's active subscription
 * @access Private
 */
router.get("/my-subscription", userSubscriptionController.getMySubscription);

/**
 * @route GET /user/subscriptions/features
 * @desc Get the current user's power/features
 * @access Private
 */
router.get("/features", userSubscriptionController.getUserFeatures);

/**
 * ─────────────────────────────────────────────
 * Subscription Action Routes
 * ─────────────────────────────────────────────
 */

/**
 * @route POST /user/subscriptions/subscribe
 * @desc Subscribe to a plan
 * @access Private
 */
router.post("/subscribe", userSubscriptionController.subscribe);

/**
 * @route POST /user/subscriptions/check-call
 * @desc Check if user can initiate an audio or video call
 * @access Private
 */
router.post("/check-call", userSubscriptionController.checkCallAccess);

/**
 * @route POST /user/subscriptions/sync
 * @desc Sync active subscriptions from RevenueCat
 * @access Private
 */
router.post("/sync", userSubscriptionController.sync);

export default router;
