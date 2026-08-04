import { firebaseMessagingService } from './firebaseMessaging.service';
import { deviceTokenService } from './deviceToken.service';
import { NotificationType } from '../constants/notificationTypes';
import logger from '../utils/logger';

export interface SendNotificationParams {
  userId: number;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>; // Ensure all values are strings for FCM
}

export class NotificationService {
  /**
   * Send a push notification to a user.
   * This handles fetching active tokens and sending via Firebase.
   * It never throws an error to the caller (business logic should not fail).
   */
  public async sendToUser(params: SendNotificationParams): Promise<void> {
    try {
      const { userId, type, title, body, data } = params;

      // Ensure data values are strictly strings
      const stringifiedData: Record<string, string> = { type };
      if (data) {
        for (const [key, value] of Object.entries(data)) {
          if (value !== undefined && value !== null) {
            stringifiedData[key] = String(value);
          }
        }
      }

      // Fetch active tokens
      const activeTokens = await deviceTokenService.getActiveTokensForUser(userId);
      if (!activeTokens || activeTokens.length === 0) {
        logger.info(`Notification requested for user ${userId}, but no active tokens found.`);
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

    } catch (error) {
      logger.error(`Failed to send notification to user ${params.userId}:`, error);
      // Do not re-throw to prevent breaking business logic flow
    }
  }

  /**
   * Send a notification to multiple users.
   */
  public async sendToUsers(userIds: number[], params: Omit<SendNotificationParams, 'userId'>): Promise<void> {
    // Send to users concurrently but gracefully handle errors for each
    await Promise.allSettled(
      userIds.map((userId) => this.sendToUser({ ...params, userId }))
    );
  }
}

export const notificationService = new NotificationService();
