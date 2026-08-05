import { DevicePlatform } from "@prisma/client";
import { Request, Response } from "express";
import { notificationService } from "../composer/composer";
import { NotificationType } from "../constants/notificationTypes";
import { deviceTokenService } from "../services/deviceToken.service";
import { firebaseMessagingService } from "../services/firebaseMessaging.service";
import logger from "../utils/logger";

export class DeviceTokenController {
   public registerToken = async (req: Request, res: Response): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const { token, platform, deviceId } = req.body;

         if (!token || !platform) {
            res.status(400).json({ success: false, message: "Token and platform are required" });
            return;
         }

         if (!Object.values(DevicePlatform).includes(platform as DevicePlatform)) {
            res.status(400).json({ success: false, message: "Invalid platform" });
            return;
         }

         await deviceTokenService.upsertToken(userId, token, platform as DevicePlatform, deviceId);

         res.status(200).json({ success: true, message: "Device token registered successfully" });
      } catch (error: any) {
         logger.error("Error in registerToken:", error);
         res.status(500).json({ success: false, message: "Internal server error" });
      }
   };

   public removeToken = async (req: Request, res: Response): Promise<void> => {
      try {
         const userId = req.user?.id;
         if (!userId) {
            res.status(401).json({ success: false, message: "Unauthorized" });
            return;
         }

         const { token } = req.body;

         if (!token) {
            res.status(400).json({ success: false, message: "Token is required" });
            return;
         }

         await deviceTokenService.deactivateToken(userId, token);

         res.status(200).json({ success: true, message: "Device token removed successfully" });
      } catch (error: any) {
         logger.error("Error in removeToken:", error);
         res.status(500).json({ success: false, message: "Internal server error" });
      }
   };

   public sendTestNotification = async (req: Request, res: Response): Promise<void> => {
      try {
         const { userId, token, title, body, type, data } = req.body;

         const targetTitle = title || "Test Push Notification";
         const targetBody = body || "This is a test push notification sent from Postman!";
         const targetType = type || NotificationType.NEW_MESSAGE;
         const customData = data || {};

         const targetUserId = userId || req.user?.id;

         if (!targetUserId && !token) {
            res.status(400).json({
               success: false,
               message: 'Please provide either a "userId", a raw FCM "token", or authenticate with a Bearer token.',
            });
            return;
         }

         if (token) {
            const messagePayload: any = {
               token,
               notification: {
                  title: targetTitle,
                  body: targetBody,
               },
               data: {
                  type: targetType,
                  ...Object.fromEntries(Object.entries(customData).map(([k, v]) => [k, String(v)])),
               },
            };

            const result = await firebaseMessagingService.sendToToken(token, messagePayload);
            res.status(200).json({
               success: true,
               message: "Test notification sent successfully to FCM token.",
               result,
            });
            return;
         }

         if (targetUserId) {
            const numUserId = Number(targetUserId);
            const activeTokens = await deviceTokenService.getActiveTokensForUser(numUserId);

            if (!activeTokens || activeTokens.length === 0) {
               res.status(404).json({
                  success: false,
                  message: `No active device tokens found for user ID ${numUserId}. Make sure the user has logged in from a mobile device.`,
               });
               return;
            }

            await notificationService.sendToUser({
               userId: numUserId,
               type: targetType as NotificationType,
               title: targetTitle,
               body: targetBody,
               data: customData,
            });

            res.status(200).json({
               success: true,
               message: `Test notification sent successfully to ${activeTokens.length} active device(s) for user ID ${numUserId}.`,
               tokensCount: activeTokens.length,
            });
            return;
         }
      } catch (error: any) {
         logger.error("Error in sendTestNotification:", error);
         res.status(500).json({
            success: false,
            message: "Failed to send test notification",
            error: error.message || error,
         });
      }
   };
}
