import { jobController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/user/jobs/popular
 * @desc    Get most popular jobs
 * @access  Private
 */
router.get("/popular", jobController.getPopularJobs);

/**
 * @route   GET /api/v1/user/jobs
 * @desc    Search/get all jobs
 * @access  Private
 */
router.get("/", jobController.getJobs);

/**
 * @route   POST /api/v1/user/jobs
 * @desc    Get or create a job
 * @access  Private
 */
router.post("/", jobController.createJob);

export default router;
