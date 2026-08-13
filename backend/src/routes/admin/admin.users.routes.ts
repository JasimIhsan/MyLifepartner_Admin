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
 * @route   GET /api/v1/admin/users/suspended
 * @desc    Get all suspended users
 * @access  Admin
 */
adminUsersRoute.get("/suspended", adminUsersController.getSuspendedUsers);

/**
 * @route   GET /api/v1/admin/users/deletion-requests
 * @desc    Get all pending deletion requests
 * @access  Admin
 */
adminUsersRoute.get("/deletion-requests", adminUsersController.getPendingDeletionRequests);

/**
 * @route   GET /api/v1/admin/users/archived
 * @desc    Get all archived (deleted) users
 * @access  Admin
 */
adminUsersRoute.get("/archived", adminUsersController.getArchivedUsers);

/**
 * @route   POST /api/v1/admin/users
 * @desc    Create a new user
 * @access  Admin
 */
adminUsersRoute.post("/", adminUsersController.createUser);

/**
 * @route   GET /api/v1/admin/users/:id
 * @desc    Get complete user details by ID
 * @access  Admin
 */
adminUsersRoute.get("/:id", adminUsersController.getUserById);

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
 * @route   PATCH /api/v1/admin/users/:id/ban
 * @desc    Ban or unban a user
 * @access  Admin
 */
adminUsersRoute.patch("/:id/ban", adminUsersController.toggleBanUser);

/**
 * @route   PATCH /api/v1/admin/users/:id/founding-member
 * @desc    Toggle founding-member status
 * @access  Admin
 */
adminUsersRoute.patch("/:id/founding-member", adminUsersController.toggleFoundingMemberStatus);

/**
 * @route   PATCH /api/v1/admin/users/:id/lift-suspension
 * @desc    Lift temporary suspension of a user
 * @access  Admin
 */
adminUsersRoute.patch("/:id/lift-suspension", adminUsersController.liftSuspension);

/**
 * @route   DELETE /api/v1/admin/users/:id
 * @desc    Delete user by ID
 * @access  Admin
 */
adminUsersRoute.delete("/:id", adminUsersController.deleteUser);

/**
 * @route   POST /api/v1/admin/users/:id/approve-deletion
 * @desc    Approve account deletion
 * @access  Admin
 */
adminUsersRoute.post("/:id/approve-deletion", adminUsersController.approveDeletionRequest);

/**
 * @route   POST /api/v1/admin/users/:id/reject-deletion
 * @desc    Reject account deletion
 * @access  Admin
 */
adminUsersRoute.post("/:id/reject-deletion", adminUsersController.rejectDeletionRequest);

export default adminUsersRoute;
