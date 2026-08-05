import { notificationController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   GET /api/v1/user/notifications/unread-count
 * @desc    Get total unread notification count
 * @access  Private
 */
router.get("/unread-count", notificationController.getUnreadCount);

/**
 * @route   GET /api/v1/user/notifications
 * @desc    Get user notifications (paginated)
 * @access  Private
 */
router.get("/", notificationController.getNotifications);

/**
 * @route   PATCH /api/v1/user/notifications/read-all
 * @desc    Mark all notifications as read for current user
 * @access  Private
 */
router.patch("/read-all", notificationController.markAllAsRead);

/**
 * @route   PATCH /api/v1/user/notifications/:id/read
 * @desc    Mark a specific notification as read
 * @access  Private
 */
router.patch("/:id/read", notificationController.markAsRead);

export default router;
