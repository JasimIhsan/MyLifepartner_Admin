import { completeProfile, getAnswers, getQuestions, saveAnswer } from "@/controllers/profile.controller";
// import { verifyJWT } from "@/middlewares/auth.middleware"; // Assuming this exists
import { Router } from "express";

const router = Router();

// router.use(verifyJWT); // Apply auth middleware to all routes

router.get("/questions/:userId", getQuestions);
router.get("/answers/:userId", getAnswers);
router.post("/questions/:questionId/answer", saveAnswer);
router.post("/complete", completeProfile);

export default router;
