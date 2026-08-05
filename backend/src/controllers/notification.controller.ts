import { Response } from "express";
import { AuthRequest } from "../types/AuthRequest";
import { NotificationService } from "../services/notification.service";
import { asyncHandler } from "../utils/asyncHandler";

export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  getNotifications = asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ status: false, message: "Unauthorized" });
    }

    const pageParam = Array.isArray(req.query.page) ? req.query.page[0] : req.query.page;
    const limitParam = Array.isArray(req.query.limit) ? req.query.limit[0] : req.query.limit;

    const page = parseInt(pageParam as string, 10) || 1;
    const limit = parseInt(limitParam as string, 10) || 20;

    const result = await this.notificationService.getNotificationsForUser(userId, page, limit);

    return res.status(200).json({
      status: true,
      message: "Notifications retrieved successfully",
      data: result,
    });
  });

  getUnreadCount = asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ status: false, message: "Unauthorized" });
    }

    const unreadCount = await this.notificationService.getUnreadCount(userId);

    return res.status(200).json({
      status: true,
      message: "Unread notification count retrieved successfully",
      data: { unreadCount },
    });
  });

  markAllAsRead = asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ status: false, message: "Unauthorized" });
    }

    await this.notificationService.markAllAsRead(userId);

    return res.status(200).json({
      status: true,
      message: "All notifications marked as read",
    });
  });

  markAsRead = asyncHandler(async (req: AuthRequest, res: Response) => {
    const userId = req.user?.id;
    if (!userId) {
      return res.status(401).json({ status: false, message: "Unauthorized" });
    }

    const notificationId = parseInt(req.params.id as string, 10);
    if (isNaN(notificationId)) {
      return res.status(400).json({ status: false, message: "Invalid notification ID" });
    }

    await this.notificationService.markAsRead(userId, notificationId);

    return res.status(200).json({
      status: true,
      message: "Notification marked as read",
    });
  });
}
