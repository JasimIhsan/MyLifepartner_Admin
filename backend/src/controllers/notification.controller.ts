import { Response } from "express";
import { AuthRequest } from "../types/AuthRequest";
import { NotificationRepository } from "../repositories/notification.repository";
import { asyncHandler } from "../utils/asyncHandler";

export class NotificationController {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  getNotifications = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ status: false, message: "Unauthorized" });
      }

      const pageParam = Array.isArray(req.query.page) ? req.query.page[0] : req.query.page;
      const limitParam = Array.isArray(req.query.limit) ? req.query.limit[0] : req.query.limit;

      const page = parseInt(pageParam as string, 10) || 1;
      const limit = parseInt(limitParam as string, 10) || 20;

      const result = await this.notificationRepository.getNotificationsForUser(userId, page, limit);

      return res.status(200).json({
        status: true,
        message: "Notifications retrieved successfully",
        data: result,
      });
    } catch (error: any) {
      return res.status(500).json({
        status: false,
        message: error?.message || "Failed to retrieve notifications",
      });
    }
  });

  markAllAsRead = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ status: false, message: "Unauthorized" });
      }

      await this.notificationRepository.markAllAsRead(userId);

      return res.status(200).json({
        status: true,
        message: "All notifications marked as read",
      });
    } catch (error: any) {
      return res.status(500).json({
        status: false,
        message: error?.message || "Failed to mark notifications as read",
      });
    }
  });

  markAsRead = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ status: false, message: "Unauthorized" });
      }

      const notificationId = parseInt(req.params.id as string, 10);
      if (isNaN(notificationId)) {
        return res.status(400).json({ status: false, message: "Invalid notification ID" });
      }

      await this.notificationRepository.markAsRead(userId, notificationId);

      return res.status(200).json({
        status: true,
        message: "Notification marked as read",
      });
    } catch (error: any) {
      return res.status(500).json({
        status: false,
        message: error?.message || "Failed to mark notification as read",
      });
    }
  });
}
