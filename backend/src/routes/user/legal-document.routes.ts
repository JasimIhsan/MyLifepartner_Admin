import { userLegalDocumentController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/user/legal/terms
 * @desc    Get latest published terms
 * @access  Public
 */
router.get("/terms", userLegalDocumentController.getLatestTerms);

/**
 * @route   GET /api/v1/user/legal/privacy
 * @desc    Get latest published privacy policy
 * @access  Public
 */
router.get("/privacy", userLegalDocumentController.getLatestPrivacyPolicy);

/**
 * @route   GET /api/v1/user/legal/accepted/:type
 * @desc    Get the version of the legal document the authenticated user accepted
 * @access  Private
 */
router.get("/accepted/:type", verifyJWT, userLegalDocumentController.getAcceptedDocument);

export default router;
