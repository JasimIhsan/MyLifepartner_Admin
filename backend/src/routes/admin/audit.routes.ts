import { Router } from "express";
import { adminAuditController } from "@/controllers/admin/admin.audit.controller";

const router = Router();

router.get("/", adminAuditController.getAuditLogs);
router.get("/:id", adminAuditController.getAuditLogById);
router.get("/:id/timeline", adminAuditController.getAuditLogTimeline);
router.get("/user/:userId", adminAuditController.getUserAuditLogs);

export default router;
