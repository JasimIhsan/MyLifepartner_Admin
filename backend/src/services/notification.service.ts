import { firebaseMessagingService } from './firebaseMessaging.service';
import { deviceTokenService } from './deviceToken.service';
import { NotificationType } from '../constants/notificationTypes';
import { NotificationRepository } from '../repositories/notification.repository';
import logger from '../utils/logger';
import { auditService } from '@/services/audit.service';
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from '@prisma/client';

export interface SendNotificationParams {
  userId: number;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>; // Ensure all values are strings for FCM
}

export class NotificationService {
  constructor(private readonly notificationRepository: NotificationRepository) {}

  /**
   * Get paginated notifications for a user.
   */
  public async getNotificationsForUser(userId: number, page: number = 1, limit: number = 20, category?: string) {
    return this.notificationRepository.getNotificationsForUser(userId, page, limit, category);
  }

  /**
   * Get total unread notifications count for a user.
   */
  public async getUnreadCount(userId: number): Promise<number> {
    return this.notificationRepository.getUnreadCount(userId);
  }

  /**
   * Mark all notifications as read for a user.
   */
  public async markAllAsRead(userId: number) {
    return this.notificationRepository.markAllAsRead(userId);
  }

  /**
   * Mark a specific notification as read.
   */
  public async markAsRead(userId: number, notificationId: number) {
    return this.notificationRepository.markAsRead(userId, notificationId);
  }

  /**
   * Saves an in-app (local database) notification for a user via repository.
   */
  public async saveInAppNotification(params: SendNotificationParams): Promise<any> {
    try {
      const { userId, type, title, body, data } = params;
      return await this.notificationRepository.createNotification({
        userId,
        type,
        title,
        body,
        data: data ? (data as any) : null,
      });
    } catch (dbError: any) {
      logger.error(`Failed to save in-app notification in DB for user ${params.userId}:`, dbError);
      
      await auditService.log({
         actorType: ActorType.SYSTEM,
         module: AuditModule.NOTIFICATION,
         action: "SAVE_IN_APP_NOTIFICATION_FAILED",
         status: AuditStatus.FAILED,
         severity: AuditSeverity.CRITICAL,
         message: `Failed to save in-app notification in DB for user ${params.userId}. Reason: ${dbError.message || "Unknown"}`,
         source: AuditSource.OTHER,
      });
      
      return null;
    }
  }

  /**
   * Sends a remote push notification (FCM) to user's registered devices.
   */
  public async sendPushNotification(params: SendNotificationParams): Promise<void> {
    try {
      const { userId, type, title, body, data } = params;

      // Ensure data values are strictly strings for FCM payload
      const stringifiedData: Record<string, string> = { type };
      if (data) {
        for (const [key, value] of Object.entries(data)) {
          if (value !== undefined && value !== null) {
            stringifiedData[key] = String(value);
          }
        }
      }

      // Fetch active device tokens
      const activeTokens = await deviceTokenService.getActiveTokensForUser(userId);
      if (!activeTokens || activeTokens.length === 0) {
        logger.info(`Push notification requested for user ${userId}, but no active device tokens found.`);
        return;
      }

      const tokens = activeTokens.map((dt: { token: string }) => dt.token);

      const payload = {
        notification: {
          title,
          body,
        },
        data: stringifiedData,
      };

      if (tokens.length === 1) {
        await firebaseMessagingService.sendToToken(tokens[0], { ...payload, token: tokens[0] });
      } else {
        await firebaseMessagingService.sendToTokens(tokens, { ...payload, tokens });
      }
    } catch (error: any) {
      logger.error(`Failed to send push notification to user ${params.userId}:`, error);

      await auditService.log({
         actorType: ActorType.SYSTEM,
         module: AuditModule.NOTIFICATION,
         action: "SEND_PUSH_NOTIFICATION_FAILED",
         status: AuditStatus.FAILED,
         severity: AuditSeverity.CRITICAL,
         message: `Failed to send push notification to user ${params.userId}. Reason: ${error.message || "Unknown"}`,
         source: AuditSource.OTHER,
      });
    }
  }

  /**
   * Send both in-app notification (DB) and push notification (FCM) to a user.
   */
  public async sendToUser(params: SendNotificationParams): Promise<void> {
    // 1. Save in-app notification locally in DB
    await this.saveInAppNotification(params);

    // 2. Send remote push notification via FCM
    await this.sendPushNotification(params);
  }

  /**
   * Send both in-app notification and push notification to multiple users.
   */
  public async sendToUsers(userIds: number[], params: Omit<SendNotificationParams, 'userId'>): Promise<void> {
    await Promise.allSettled(
      userIds.map((userId) => this.sendToUser({ ...params, userId }))
    );
  }
}
