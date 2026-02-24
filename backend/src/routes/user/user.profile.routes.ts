import { multerConfig } from "@/config/multer.config";
import { profileController } from "@/controllers/user/profile.controller";
import { profileImageController } from "@/controllers/user/profile.image.controller";
// import { verifyJWT } from "@/middlewares/auth.middleware"; // Assuming this exists
import { Router } from "express";

const router = Router();

// router.use(verifyJWT); // Apply auth middleware to all routes

router.get("/sections", profileController.getSections);
router.get("/questions/:userId", profileController.getQuestions);
router.get("/answers/:userId", profileController.getAnswers);
router.post("/questions/save-answer/:userId/:questionId", profileController.saveAnswer);
router.patch("/complete/:userId", profileController.completeProfile);
router.get("/completion-status/:userId", profileController.getCompletionStatus);

// Image Profile Routes
router.post("/upload-image/:userId", multerConfig.single("image"), profileImageController.uploadImage);
router.delete("/remove-image/:userId/:imageId", profileImageController.removeImage);
router.patch("/set-primary/:userId/:imageId", profileImageController.setPrimaryImage);
router.get("/images/:userId", profileImageController.getImages);
router.post("/complete-image-upload/:userId", profileImageController.completeImageUpload);
router.post("/upload-selfie/:userId", multerConfig.single("image"), profileImageController.uploadSelfie);

export default router;
