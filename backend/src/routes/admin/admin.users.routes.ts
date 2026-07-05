import { adminUsersController } from "@/composer/composer";
import { Router } from "express";

const adminUsersRoute = Router();

/**
 * @route   GET /api/v1/admin/users
 * @desc    Get all users (with pagination and filters)
 * @access  Admin
 */
adminUsersRoute.get("/", adminUsersController.getAllUsers);

/**
 * @route   POST /api/v1/admin/users
 * @desc    Create a new user
 * @access  Admin
 */
adminUsersRoute.post("/", adminUsersController.createUser);

/**
 * @route   PUT /api/v1/admin/users/:id
 * @desc    Update user by ID
 * @access  Admin
 */
adminUsersRoute.put("/:id", adminUsersController.updateUser);

/**
 * @route   GET /api/v1/admin/users/:id/selfie-url
 * @desc    Get verification selfie image URL of a user
 * @access  Admin
 */
adminUsersRoute.get("/:id/selfie-url", adminUsersController.getSelfieUrl);

/**
 * @route   GET /api/v1/admin/users/:id/images
 * @desc    Get all profile images of a user
 * @access  Admin
 */
adminUsersRoute.get("/:id/images", adminUsersController.getUserImages);

/**
 * @route   PATCH /api/v1/admin/users/:id/verify-profile
 * @desc    Update user profile verification status
 * @access  Admin
 */
adminUsersRoute.patch("/:id/verify-profile", adminUsersController.verifyProfile);

/**
 * @route   PATCH /api/v1/admin/users/:id/block-status
 * @desc    Block or unblock a user
 * @access  Admin
 */
adminUsersRoute.patch("/:id/block-status", adminUsersController.toggleBlockUser);

/**
 * @route   DELETE /api/v1/admin/users/:id
 * @desc    Delete user by ID
 * @access  Admin
 */
adminUsersRoute.delete("/:id", adminUsersController.deleteUser);

export default adminUsersRoute;
