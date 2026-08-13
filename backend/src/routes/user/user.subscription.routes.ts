import { Router } from "express";

import { userSubscriptionController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { subscriptionActionLimiter, webhookLimiter } from "@/middlewares/rateLimiter.middleware";

const router = Router();

/**
 * ─────────────────────────────────────────────
 * Public Routes
 * ─────────────────────────────────────────────
 */

/**
 * @route POST /user/subscription/webhook
 * @desc RevenueCat webhook endpoint
 * @access Public (protected by REVENUECAT_WEBHOOK_SECRET signature check
 *
 * webhookLimiter is applied here BEFORE auth middleware to rate-limit
 * unauthenticated callers
 */
router.post("/webhook", webhookLimiter, userSubscriptionController.webhook);

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
 * @route GET /user/subscription/plans
 * @desc Get available subscription plans
 * @access Private
 */
router.get("/plans", userSubscriptionController.getPlans);

/**
 * @route GET /user/subscription/my-subscription
 * @desc Get the current user's active subscription
 * @access Private
 */
router.get("/my-subscription", userSubscriptionController.getMySubscription);

/**
 * @route GET /user/subscription/features
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
 * @route POST /user/subscription/subscribe
 * @desc Subscribe to the FREE plan (paid plans must be purchased via store)
 * @access Private
 */
router.post("/subscribe", subscriptionActionLimiter, userSubscriptionController.subscribe);

/**
 * @route POST /user/subscription/verify-purchase
 * @desc Verifies a RevenueCat purchase and immediately activates the plan in the DB.
 *       Call this right after RevenueCat purchase succeeds in Flutter.
 *       Body: { storeTransactionId, productId, store, environment }
 * @access Private
 */
router.post("/verify-purchase", subscriptionActionLimiter, userSubscriptionController.verifyPurchase);

/**
 * @route POST /user/subscription/check-call
 * @desc Check if user can initiate an audio or video call
 * @access Private
 */
router.post("/check-call", userSubscriptionController.checkCallAccess);

/**
 * @route POST /user/subscription/sync
 * @desc Sync active subscriptions from RevenueCat (rate limited)
 * @access Private
 */
router.post("/sync", subscriptionActionLimiter, userSubscriptionController.sync);

export default router;
