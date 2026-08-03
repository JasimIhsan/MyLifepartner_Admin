import { Router } from "express";
import { getReports, getReportById, updateReportStatus, takeModerationAction, getUserHistory } from "@/controllers/admin/admin.report.controller";
import { authenticateAdmin } from "@/middlewares/admin.auth.middleware";

const router = Router();

// Apply admin authentication middleware
router.use(authenticateAdmin);

// List all reports with optional filters
router.get("/", getReports);

// Get specific report details
router.get("/:id", getReportById);

// Update report status (e.g., assign, mark as resolved)
router.patch("/:id/status", updateReportStatus);

// Take moderation action against the reported user
router.post("/:id/action", takeModerationAction);

// Get moderation history for a specific user
router.get("/users/:userId/history", getUserHistory);

export default router;
