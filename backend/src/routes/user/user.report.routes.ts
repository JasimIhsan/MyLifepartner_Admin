import { multerConfig } from "@/config/multer.config";
import { getUserReports, submitReport } from "@/controllers/user/user.report.controller";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

// Apply authentication middleware to all report routes
router.use(verifyJWT);

// Submit a new report with optional screenshots (up to 5)
router.post("/", multerConfig.array("screenshots", 5), submitReport);

// Get user's submitted reports
router.get("/", getUserReports);

export default router;
