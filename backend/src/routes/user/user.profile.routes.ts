import { profileController, profileImageController, privacyController } from "@/composer/composer";
import { multerConfig } from "@/config/multer.config";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { validate } from "@/middlewares/validate.middleware";
import { profileSchema, partnerPreferenceSchema } from "@/validators/profile.validator";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   GET /api/v1/user/profile/sections
 * @desc    Get all questionnaire sections for profile setup
 * @access  Private
 */
router.get("/sections", profileController.getSections);

/**
 * @route   GET /api/v1/user/profile/questions or /questions/:userId
 * @desc    Get all questions for a user profile
 * @access  Private
 */
router.get("/questions", profileController.getQuestions);
router.get("/questions/:userId", profileController.getQuestions);

/**
 * @route   GET /api/v1/user/profile/answers or /answers/:userId
 * @desc    Get answers supplied by a user
 * @access  Private
 */
router.get("/answers", profileController.getAnswers);
router.get("/answers/:userId", profileController.getAnswers);

/**
 * @route   POST /api/v1/user/profile/questions/save-answer/:questionId or /save-answer/:userId/:questionId
 * @desc    Save a response to a specific question
 * @access  Private
 */
router.post("/questions/save-answer/:questionId", profileController.saveAnswer);
router.post("/questions/save-answer/:userId/:questionId", profileController.saveAnswer);

/**
 * @route   PATCH /api/v1/user/profile/complete or /complete/:userId
 * @desc    Mark user profile setup as complete
 * @access  Private
 */
router.patch("/complete", profileController.completeProfile);
router.patch("/complete/:userId", profileController.completeProfile);

/**
 * @route   GET /api/v1/user/profile/completion-status or /completion-status/:userId
 * @desc    Get progress and completeness percentage of user profile
 * @access  Private
 */
router.get("/completion-status", profileController.getCompletionStatus);
router.get("/completion-status/:userId", profileController.getCompletionStatus);

/**
 * @route   PATCH /api/v1/user/profile/update or /update/:userId
 * @desc    Update user profile details (height, occupation, etc)
 * @access  Private
 */
router.patch("/update", validate(profileSchema), profileController.updateProfile);
router.patch("/update/:userId", validate(profileSchema), profileController.updateProfile);

/**
 * @route   GET / PATCH /api/v1/user/profile/partner-preference or /partner-preference/:userId
 * @desc    Update partner preferences details (age range, religion, etc)
 * @access  Private
 */
router.get("/partner-preference", profileController.getPartnerPreference);
router.get("/partner-preference/:userId", profileController.getPartnerPreference);
router.patch("/partner-preference", validate(partnerPreferenceSchema), profileController.updatePartnerPreference);
router.patch("/partner-preference/:userId", validate(partnerPreferenceSchema), profileController.updatePartnerPreference);

/**
 * @route   PATCH /api/v1/user/profile/privacy or /privacy/:userId
 * @desc    Update privacy settings for the profile (enable/disable image blurring)
 * @access  Private
 */
router.patch("/privacy", privacyController.updatePrivacySettings);
router.patch("/privacy/:userId", privacyController.updatePrivacySettings);

// Image Profile Routes

/**
 * @route   POST /api/v1/user/profile/upload-image or /upload-image/:userId
 * @desc    Upload profile image for user
 * @access  Private
 */
router.post("/upload-image", multerConfig.single("image"), profileImageController.uploadImage);
router.post("/upload-image/:userId", multerConfig.single("image"), profileImageController.uploadImage);

/**
 * @route   POST /api/v1/user/profile/images/presigned-urls
 * @desc    Get fresh presigned URLs for profile image IDs
 * @access  Private
 */
router.post("/images/presigned-urls", profileImageController.getPresignedImageUrls);

/**
 * @route   PUT /api/v1/user/profile/replace-image/:imageId or /replace-image/:userId/:imageId
 * @desc    Replace a specific profile image for user
 * @access  Private
 */
router.put("/replace-image/:imageId", multerConfig.single("image"), profileImageController.replaceImage);
router.put("/replace-image/:userId/:imageId", multerConfig.single("image"), profileImageController.replaceImage);

/**
 * @route   PATCH /api/v1/user/profile/set-primary/:imageId or /set-primary/:userId/:imageId
 * @desc    Set a profile image as primary profile picture
 * @access  Private
 */
router.patch("/set-primary/:imageId", profileImageController.setPrimaryImage);
router.patch("/set-primary/:userId/:imageId", profileImageController.setPrimaryImage);

/**
 * @route   DELETE /api/v1/user/profile/delete-image/:imageId or /delete-image/:userId/:imageId
 * @desc    Deletes a specific profile image for user
 * @access  Private
 */
router.delete("/delete-image/:imageId", profileImageController.deleteImage);
router.delete("/delete-image/:userId/:imageId", profileImageController.deleteImage);

/**
 * @route   GET /api/v1/user/profile/images or /images/:userId
 * @desc    Get all profile images of user
 * @access  Private
 */
router.get("/images", verifyJWT, profileImageController.getImages);
router.get("/images/:userId", verifyJWT, profileImageController.getImages);

/**
 * @route   POST /api/v1/user/profile/complete-image-upload or /complete-image-upload/:userId
 * @desc    Finalize image uploading steps
 * @access  Private
 */
router.post("/complete-image-upload", profileImageController.completeImageUpload);
router.post("/complete-image-upload/:userId", profileImageController.completeImageUpload);

/**
 * @route   POST /api/v1/user/profile/upload-selfie or /upload-selfie/:userId
 * @desc    Upload selfies for profile verification (front, left, right views)
 * @access  Private
 */
router.post(
   "/upload-selfie",
   multerConfig.fields([
      { name: "frontImage", maxCount: 1 },
      { name: "leftImage", maxCount: 1 },
      { name: "rightImage", maxCount: 1 },
   ]),
   profileImageController.uploadSelfie
);
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

