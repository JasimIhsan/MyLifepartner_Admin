import { profileController, profileImageController } from "@/composer/composer";
import { multerConfig } from "@/config/multer.config";
import { validate } from "@/middlewares/validate.middleware";
import { basicProfileSchema, partnerPreferenceSchema } from "@/validators/profile.validator";
import { Router } from "express";

const router = Router();

router.get("/sections", profileController.getSections);
router.get("/questions/:userId", profileController.getQuestions);
router.get("/answers/:userId", profileController.getAnswers);
router.post("/questions/save-answer/:userId/:questionId", profileController.saveAnswer);
router.patch("/complete/:userId", profileController.completeProfile);
router.get("/completion-status/:userId", profileController.getCompletionStatus);
router.patch("/basic-profile/:userId", validate(basicProfileSchema), profileController.updateBasicProfile);
router.patch("/partner-preference/:userId", validate(partnerPreferenceSchema), profileController.updatePartnerPreference);

// Image Profile Routes
router.post("/upload-image/:userId", multerConfig.single("image"), profileImageController.uploadImage);
router.delete("/remove-image/:userId/:imageId", profileImageController.removeImage);
router.patch("/set-primary/:userId/:imageId", profileImageController.setPrimaryImage);
router.get("/images/:userId", profileImageController.getImages);
router.post("/complete-image-upload/:userId", profileImageController.completeImageUpload);
router.post("/upload-selfie/:userId", multerConfig.single("image"), profileImageController.uploadSelfie);

export default router;
