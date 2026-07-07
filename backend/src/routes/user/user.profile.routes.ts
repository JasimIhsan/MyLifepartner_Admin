import { profileController, profileImageController } from "@/composer/composer";
import { multerConfig } from "@/config/multer.config";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { validate } from "@/middlewares/validate.middleware";
import { basicProfileSchema, partnerPreferenceSchema } from "@/validators/profile.validator";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/user/profile/sections
 * @desc    Get all questionnaire sections for profile setup
 * @access  Private
 */
router.get("/sections", profileController.getSections);

/**
 * @route   GET /api/v1/user/profile/questions/:userId
 * @desc    Get all questions for a specific user profile
 * @access  Private
 */
router.get("/questions/:userId", profileController.getQuestions);

/**
 * @route   GET /api/v1/user/profile/answers/:userId
 * @desc    Get answers supplied by a user
 * @access  Private
 */
router.get("/answers/:userId", profileController.getAnswers);

/**
 * @route   POST /api/v1/user/profile/questions/save-answer/:userId/:questionId
 * @desc    Save a response to a specific question
 * @access  Private
 */
router.post("/questions/save-answer/:userId/:questionId", profileController.saveAnswer);

/**
 * @route   PATCH /api/v1/user/profile/complete/:userId
 * @desc    Mark user profile setup as complete
 * @access  Private
 */
router.patch("/complete/:userId", profileController.completeProfile);

/**
 * @route   GET /api/v1/user/profile/completion-status/:userId
 * @desc    Get progress and completeness percentage of user profile
 * @access  Private
 */
router.get("/completion-status/:userId", profileController.getCompletionStatus);

/**
 * @route   PATCH /api/v1/user/profile/basic-profile/:userId
 * @desc    Update basic user profile details (height, occupation, etc)
 * @access  Private
 */
router.patch("/basic-profile/:userId", validate(basicProfileSchema), profileController.updateBasicProfile);

/**
 * @route   PATCH /api/v1/user/profile/partner-preference/:userId
 * @desc    Update partner preferences details (age range, religion, etc)
 * @access  Private
 */
router.patch("/partner-preference/:userId", validate(partnerPreferenceSchema), profileController.updatePartnerPreference);

// Image Profile Routes

/**
 * @route   POST /api/v1/user/profile/upload-image/:userId
 * @desc    Upload profile image for user
 * @access  Private
 */
router.post("/upload-image/:userId", multerConfig.single("image"), profileImageController.uploadImage);

/**
 * @route   DELETE /api/v1/user/profile/remove-image/:userId/:imageId
 * @desc    Remove a specific profile image for user
 * @access  Private
 */
router.delete("/remove-image/:userId/:imageId", profileImageController.removeImage);

/**
 * @route   PATCH /api/v1/user/profile/set-primary/:userId/:imageId
 * @desc    Set a profile image as primary profile picture
 * @access  Private
 */
router.patch("/set-primary/:userId/:imageId", profileImageController.setPrimaryImage);

/**
 * @route   GET /api/v1/user/profile/images/:userId
 * @desc    Get all profile images of user
 * @access  Private
 */
router.get("/images/:userId", verifyJWT, profileImageController.getImages);

/**
 * @route   POST /api/v1/user/profile/complete-image-upload/:userId
 * @desc    Finalize image uploading steps
 * @access  Private
 */
router.post("/complete-image-upload/:userId", profileImageController.completeImageUpload);

/**
 * @route   POST /api/v1/user/profile/upload-selfie/:userId
 * @desc    Upload selfies for profile verification (front, left, right views)
 * @access  Private
 */
router.post(
   "/upload-selfie/:userId",
   multerConfig.fields([
      { name: "frontImage", maxCount: 1 },
      { name: "leftImage", maxCount: 1 },
      { name: "rightImage", maxCount: 1 },
   ]),
   profileImageController.uploadSelfie
);

export default router;
