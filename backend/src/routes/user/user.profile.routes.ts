import { completeProfile, getAnswers, getQuestions, getSections, saveAnswer } from "@/controllers/user/profile.controller";
// import { verifyJWT } from "@/middlewares/auth.middleware"; // Assuming this exists
import { Router } from "express";

const router = Router();

// router.use(verifyJWT); // Apply auth middleware to all routes

router.get("/sections", getSections);
router.get("/questions/:userId", getQuestions);
router.get("/answers/:userId", getAnswers);
router.post("/questions/save-answer/:userId/:questionId", saveAnswer);
router.patch("/complete/:userId", completeProfile);

export default router;
