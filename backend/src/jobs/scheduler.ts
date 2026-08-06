import cron from "node-cron";
import logger from "../utils/logger";
import { runBroadcastNotificationJob } from "./broadcastNotification.job";

export function initializeScheduler() {
   const cronSchedule = "0 10 * * *"; // Default: Everyday at 10:00 AM

   if (!cron.validate(cronSchedule)) {
      logger.error(`Invalid cron expression for push broadcast job: ${cronSchedule}`);
      return;
   }

   logger.info(`Initializing Push Broadcast Cron Scheduler with expression: "${cronSchedule}"`);

   cron.schedule(cronSchedule, async () => {
      logger.info("⏰ Executing scheduled push notification broadcast job...");
      try {
         const result = await runBroadcastNotificationJob("New Profiles Available!", "Hey, Checkout the application to find new profiles.");
         logger.info(`⏰ Scheduled job result: ${result.message}`);
      } catch (error) {
         logger.error("⏰ Scheduled job failed:", error);
      }
   });
}
