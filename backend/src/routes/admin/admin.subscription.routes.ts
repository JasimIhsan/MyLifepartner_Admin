import { adminSubscriptionController } from "@/composer/composer";
import { Router } from "express";

const adminSubscriptionRoute = Router();

// ══════════════════════════════════════════════════════
// Plan Routes  –  /admin/subscriptions
// ══════════════════════════════════════════════════════

/**
 * @route   POST /api/v1/admin/subscriptions
 * @desc    Create a new subscription plan
 * @access  Admin
 */
adminSubscriptionRoute.post("/", adminSubscriptionController.createPlan);

/**
 * @route   GET /api/v1/admin/subscriptions
 * @desc    Get all subscription plans
 * @access  Admin
 */
adminSubscriptionRoute.get("/", adminSubscriptionController.getPlans);

/**
 * @route   GET /api/v1/admin/subscriptions/:planId
 * @desc    Get subscription plan details by ID
 * @access  Admin
 */
adminSubscriptionRoute.get("/:planId", adminSubscriptionController.getPlanById);

/**
 * @route   PATCH /api/v1/admin/subscriptions/:planId
 * @desc    Update subscription plan by ID
 * @access  Admin
 */
adminSubscriptionRoute.patch("/:planId", adminSubscriptionController.updatePlan);

/**
 * @route   DELETE /api/v1/admin/subscriptions/:planId
 * @desc    Delete subscription plan by ID
 * @access  Admin
 */
adminSubscriptionRoute.delete("/:planId", adminSubscriptionController.deletePlan);

// ══════════════════════════════════════════════════════
// Feature Routes  –  nested under plans
// ══════════════════════════════════════════════════════

/**
 * @route   POST /api/v1/admin/subscriptions/:planId/features
 * @desc    Add features to a subscription plan
 * @access  Admin
 */
adminSubscriptionRoute.post("/:planId/features", adminSubscriptionController.addFeatures);

/**
 * @route   PATCH /api/v1/admin/subscriptions/:planId/features/:featureId
 * @desc    Update a feature mapping inside a plan
 * @access  Admin
 */
adminSubscriptionRoute.patch("/:planId/features/:featureId", adminSubscriptionController.updatePlanFeature);

/**
 * @route   DELETE /api/v1/admin/subscriptions/:planId/features/:featureId
 * @desc    Delete a feature mapping from a plan
 * @access  Admin
 */
adminSubscriptionRoute.delete("/:planId/features/:featureId", adminSubscriptionController.deletePlanFeature);

export default adminSubscriptionRoute;
