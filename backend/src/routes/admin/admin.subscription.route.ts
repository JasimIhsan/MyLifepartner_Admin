import { adminSubscriptionController } from "@/composer/composer";
import { Router } from "express";

const adminSubscriptionRoute = Router();

// ══════════════════════════════════════════════════════
// Plan Routes  –  /admin/plans
// ══════════════════════════════════════════════════════
adminSubscriptionRoute.post("/", adminSubscriptionController.createPlan);
adminSubscriptionRoute.get("/", adminSubscriptionController.getPlans);
adminSubscriptionRoute.get("/:planId", adminSubscriptionController.getPlanById);
adminSubscriptionRoute.patch("/:planId", adminSubscriptionController.updatePlan);
adminSubscriptionRoute.delete("/:planId", adminSubscriptionController.deletePlan);

// ══════════════════════════════════════════════════════
// Feature Routes  –  nested under plans
// ══════════════════════════════════════════════════════
adminSubscriptionRoute.post("/:planId/features", adminSubscriptionController.addFeatures);

export default adminSubscriptionRoute;
