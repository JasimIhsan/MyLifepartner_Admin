import { imageAccessRequestController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   POST /api/v1/user/image-access/:targetUserId/request
 * @desc    Requests image access to another user's profile
 * @access  Private
 */
router.post("/:targetUserId/request", imageAccessRequestController.requestAccess);

/**
 * @route   GET /api/v1/user/image-access/received
 * @desc    Get received image access requests
 * @access  Private
 */
router.get("/received", imageAccessRequestController.getReceivedRequests);

/**
 * @route   GET /api/v1/user/image-access/sent
 * @desc    Get sent image access requests
 * @access  Private
 */
router.get("/sent", imageAccessRequestController.getSentRequests);

/**
 * @route   PATCH /api/v1/user/image-access/:requestId/approve
 * @desc    Approve a pending image access request
 * @access  Private
 */
router.patch("/:requestId/approve", imageAccessRequestController.approveRequest);

/**
 * @route   PATCH /api/v1/user/image-access/:requestId/reject
 * @desc    Reject a pending image access request
 * @access  Private
 */
router.patch("/:requestId/reject", imageAccessRequestController.rejectRequest);

/**
 * @route   PATCH /api/v1/user/image-access/:requestId/cancel
 * @desc    Cancel a pending sent image access request
 * @access  Private
 */
router.patch("/:requestId/cancel", imageAccessRequestController.cancelRequest);

/**
 * @route   PATCH /api/v1/user/image-access/:requestId/revoke
 * @desc    Revoke an approved image access request
 * @access  Private
 */
router.patch("/:requestId/revoke", imageAccessRequestController.revokeRequest);

export default router;
