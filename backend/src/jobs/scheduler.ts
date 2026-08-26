import cron from "node-cron";
import logger from "../utils/logger";
import { runBroadcastNotificationJob } from "./broadcastNotification.job";
import { runAccountDeletionJob } from "./accountDeletion.job";

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
         const result = await runBroadcastNotificationJob("Someone New Might Be Waiting 👀", "New profiles are ready to explore. Take a look and find your next connection.");
         logger.info(`⏰ Scheduled job result: ${result.message}`);
      } catch (error) {
         logger.error("⏰ Scheduled job failed:", error);
      }
   });

   const deletionCronSchedule = "0 0 * * *"; // Midnight every day
   logger.info(`Initializing Account Deletion Cron Scheduler with expression: "${deletionCronSchedule}"`);

   cron.schedule(deletionCronSchedule, async () => {
      logger.info("⏰ Executing scheduled account deletion job...");
      try {
         const result = await runAccountDeletionJob();
         logger.info(`⏰ Scheduled deletion job result: ${result.message}`);
      } catch (error) {
         logger.error("⏰ Scheduled deletion job failed:", error);
      }
   });
}
