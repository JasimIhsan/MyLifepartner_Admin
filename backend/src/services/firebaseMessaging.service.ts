import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging, Message, MulticastMessage } from 'firebase-admin/messaging';
import { deviceTokenService } from './deviceToken.service';
import logger from '../utils/logger';

// Initialize Firebase Admin SDK
// Environment variables should be defined in .env
const projectId = process.env.FIREBASE_PROJECT_ID;
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
// Handle escaped newlines in the private key if provided directly in .env
const privateKey = process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n');

if (!getApps().length) {
  if (projectId && clientEmail && privateKey) {
    initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
    logger.info('Firebase Admin SDK initialized successfully.');
  } else {
    logger.warn('Firebase Admin SDK credentials not fully provided. Push notifications may fail.');
    // Initialize without credentials (might fail later if trying to send)
    initializeApp();
  }
}

export class FirebaseMessagingService {
  /**
   * Send a notification to a specific token.
   */
  public async sendToToken(token: string, payload: Message) {
    try {
      const response = await getMessaging().send({
        ...payload,
        token,
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              sound: 'default',
            },
          },
        },
      });
      logger.info(`Successfully sent message to token: ${this.maskToken(token)}`);
      return response;
    } catch (error: any) {
      this.handleFirebaseError(error, token);
      throw error;
    }
  }

  /**
   * Send a notification to multiple tokens (multicast).
   */
  public async sendToTokens(tokens: string[], payload: MulticastMessage) {
    if (tokens.length === 0) return null;

    try {
      const response = await getMessaging().sendEachForMulticast({
        ...payload,
        tokens,
        android: {
          priority: 'high',
        },
        apns: {
          payload: {
            aps: {
              contentAvailable: true,
              sound: 'default',
            },
          },
        },
      });

      logger.info(`Multicast message sent. Success: ${response.successCount}, Failure: ${response.failureCount}`);

      // Handle failures and remove invalid tokens
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp: any, idx: number) => {
          if (!resp.success && resp.error) {
            const token = tokens[idx];
            failedTokens.push(token);
            this.handleFirebaseError(resp.error, token);
          }
        });
      }

      return response;
    } catch (error: any) {
      logger.error('Error sending multicast message', error);
      throw error;
    }
  }

  private handleFirebaseError(error: any, token: string) {
    const errorCode = error.code || (error.errorInfo && error.errorInfo.code);
    logger.error(`Firebase messaging error for token ${this.maskToken(token)}: ${errorCode || error.message}`);

    if (
      errorCode === 'messaging/registration-token-not-registered' ||
      errorCode === 'messaging/invalid-registration-token'
    ) {
      logger.info(`Removing invalid FCM token: ${this.maskToken(token)}`);
      // Fire and forget invalid token removal
      deviceTokenService.removeInvalidToken(token).catch(e => {
        logger.error(`Failed to remove invalid token ${this.maskToken(token)} from DB`, e);
      });
    }
  }

  private maskToken(token: string): string {
    if (!token || token.length < 10) return '***';
    return `${token.substring(0, 5)}...${token.substring(token.length - 5)}`;
  }
}

export const firebaseMessagingService = new FirebaseMessagingService();
