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
 * @route   GET /api/v1/user/profile/questions
 * @desc    Get all questions for authenticated user profile
 * @access  Private
 */
router.get("/questions", profileController.getQuestions);

/**
 * @route   GET /api/v1/user/profile/answers
 * @desc    Get answers supplied by authenticated user
 * @access  Private
 */
router.get("/answers", profileController.getAnswers);

/**
 * @route   POST /api/v1/user/profile/questions/save-answer/:questionId
 * @desc    Save a response to a specific question
 * @access  Private
 */
router.post("/questions/save-answer/:questionId", profileController.saveAnswer);

/**
 * @route   PATCH /api/v1/user/profile/complete
 * @desc    Mark user profile setup as complete
 * @access  Private
 */
router.patch("/complete", profileController.completeProfile);

/**
 * @route   GET /api/v1/user/profile/completion-status
 * @desc    Get progress and completeness percentage of user profile
 * @access  Private
 */
router.get("/completion-status", profileController.getCompletionStatus);

/**
 * @route   PATCH /api/v1/user/profile/update
 * @desc    Update user profile details (height, occupation, etc)
 * @access  Private
 */
router.patch("/update", validate(profileSchema), profileController.updateProfile);

/**
 * @route   GET / PATCH /api/v1/user/profile/partner-preference
 * @desc    Update partner preferences details (age range, religion, etc)
 * @access  Private
 */
router.get("/partner-preference", profileController.getPartnerPreference);
router.patch("/partner-preference", validate(partnerPreferenceSchema), profileController.updatePartnerPreference);

/**
 * @route   PATCH /api/v1/user/profile/privacy
 * @desc    Update privacy settings for the profile (enable/disable image blurring)
 * @access  Private
 */
router.patch("/privacy", privacyController.updatePrivacySettings);

// Image Profile Routes

/**
 * @route   POST /api/v1/user/profile/upload-image
 * @desc    Upload profile image for user
 * @access  Private
 */
router.post("/upload-image", multerConfig.single("image"), profileImageController.uploadImage);

/**
 * @route   POST /api/v1/user/profile/images/presigned-urls
 * @desc    Get fresh presigned URLs for profile image IDs
 * @access  Private
 */
router.post("/images/presigned-urls", profileImageController.getPresignedImageUrls);

/**
 * @route   PUT /api/v1/user/profile/replace-image/:imageId
 * @desc    Replace a specific profile image for user
 * @access  Private
 */
router.put("/replace-image/:imageId", multerConfig.single("image"), profileImageController.replaceImage);

/**
 * @route   PATCH /api/v1/user/profile/set-primary/:imageId
 * @desc    Set a profile image as primary profile picture
 * @access  Private
 */
router.patch("/set-primary/:imageId", profileImageController.setPrimaryImage);

/**
 * @route   DELETE /api/v1/user/profile/delete-image/:imageId
 * @desc    Deletes a specific profile image for user
 * @access  Private
 */
router.delete("/delete-image/:imageId", profileImageController.deleteImage);

/**
 * @route   GET /api/v1/user/profile/images
 * @desc    Get all profile images of user
 * @access  Private
 */
router.get("/images", profileImageController.getImages);

/**
 * @route   POST /api/v1/user/profile/complete-image-upload
 * @desc    Finalize image uploading steps
 * @access  Private
 */
router.post("/complete-image-upload", profileImageController.completeImageUpload);

/**
 * @route   POST /api/v1/user/profile/upload-selfie
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

export default router;


