import prisma from "../config/prisma";
import { firebaseMessagingService } from "../services/firebaseMessaging.service";
import logger from "../utils/logger";

export async function runBroadcastNotificationJob(title: string = "Someone New Might Be Waiting 👀", body: string = "New profiles are ready to explore. Take a look and find your next connection."): Promise<{ success: boolean; totalTokens: number; message: string }> {
   logger.info("Starting broadcast notification job...");

   try {
      const activeDeviceTokens = await prisma.deviceToken.findMany({
         where: {
            isActive: true,
            user: {
               isBanned: false,
               isSuspended: false,
               isDeleted: false,
               isDeleteRequested: false,
               deleteRequestStatus: { not: "PENDING" },
            },
         },
         select: {
            token: true,
            userId: true,
         },
      });

      if (!activeDeviceTokens || activeDeviceTokens.length === 0) {
         logger.info("No active device tokens found in the database.");
         return { success: true, totalTokens: 0, message: "No active device tokens found" };
      }

      // De-duplicate tokens if any
      const tokens = Array.from(new Set(activeDeviceTokens.map((dt) => dt.token)));
      logger.info(`Found ${tokens.length} unique active device token(s) across ${activeDeviceTokens.length} record(s).`);

      const payload = {
         notification: {
            title,
            body,
         },
         data: {
            type: "GENERAL_BROADCAST",
            click_action: "FLUTTER_NOTIFICATION_CLICK",
         },
      };

      if (tokens.length === 1) {
         await firebaseMessagingService.sendToToken(tokens[0], {
            ...payload,
            token: tokens[0],
         });
         logger.info("Successfully sent push notification to 1 token.");
      } else {
         const response = await firebaseMessagingService.sendToTokens(tokens, {
            ...payload,
            tokens,
         });
         logger.info(`Broadcast completed. Success: ${response?.successCount ?? 0}, Failure: ${response?.failureCount ?? 0}`);
      }

      return {
         success: true,
         totalTokens: tokens.length,
         message: `Broadcast pushed successfully to ${tokens.length} token(s).`,
      };
   } catch (error: any) {
      logger.error("Error running broadcast notification job:", error);
      throw error;
   }
}
