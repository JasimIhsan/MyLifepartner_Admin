import { userController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   GET /api/v1/user
 * @desc    Get list of users
 * @access  Private
 */
router.get("/", userController.getUsers);

/**
 * @route   GET /api/v1/user/:id
 * @desc    Get user profile details by ID
 * @access  Private
 */
router.get("/:id", userController.getUserById);

/**
 * @route   POST /api/v1/user
 * @desc    Create a new user profile
 * @access  Private
 */
router.post("/", userController.createUser);

/**
 * @route   PATCH /api/v1/user/:id
 * @desc    Update user profile by ID
 * @access  Private
 */
router.patch("/:id", userController.updateUser);

export default router;
