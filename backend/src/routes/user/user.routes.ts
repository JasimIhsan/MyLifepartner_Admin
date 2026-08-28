import { userController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

/**
 * @route   GET /api/v1/user/account-deletion/verify
 * @desc    Verify account deletion request
 * @access  Public
 */
router.get("/account-deletion/verify", userController.verifyAccountDeletion);

router.use(verifyJWT);

/**
 * @route   POST /api/v1/user/account-deletion/request
 * @desc    Request account deletion
 * @access  Private
 */
router.post("/account-deletion/request", userController.requestAccountDeletion);

/**
 * @route   GET /api/v1/user/export-data
 * @desc    Export user data to PDF
 * @access  Private
 */
router.get("/export-data", userController.exportUserData);

/**
 * @route   GET /api/v1/user/profile
 * @desc    Get current authenticated user profile
 * @access  Private
 */
router.get("/profile", userController.getProfile);

/**
 * @route   PATCH /api/v1/user/profile
 * @desc    Update current authenticated user profile
 * @access  Private
 */
router.patch("/profile", userController.updateUser);

/**
 * @route   GET /api/v1/user
 * @desc    Get list of users
 * @access  Private
 */
router.get("/", userController.getUsers);

/**
 * @route   POST /api/v1/user
 * @desc    Create a new user profile
 * @access  Private
 */
router.post("/", userController.createUser);

export default router;


