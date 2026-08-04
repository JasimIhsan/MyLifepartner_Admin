import { adminReportController } from "@/composer/composer";
import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";
import { Router } from "express";

const router = Router();

// Apply admin authentication middleware
router.use(authenticateAdmin);

// List all reports with optional filters
router.get("/", adminReportController.getReports);

// Get specific report details
router.get("/:id", adminReportController.getReportById);

// Update report status (e.g., assign, mark as resolved)
router.patch("/:id/status", adminReportController.updateReportStatus);

// Take moderation action against the reported user
router.post("/:id/action", adminReportController.takeModerationAction);

// Get moderation history for a specific user
router.get("/users/:userId/history", adminReportController.getUserHistory);

export default router;
