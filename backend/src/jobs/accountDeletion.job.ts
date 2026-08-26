import prisma from "../config/prisma";
import { accountDeletionService } from "../composer/composer";
import logger from "../utils/logger";

export async function runAccountDeletionJob(): Promise<{ success: boolean; processed: number; message: string }> {
   logger.info("Starting automated account deletion job...");

   try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      // Find all users who requested deletion more than 30 days ago
      // and are still in PENDING status.
      const pendingDeletions = await prisma.user.findMany({
         where: {
            deleteRequestStatus: "PENDING",
            isDeleteRequested: true,
            deleteRequestedAt: {
               lte: thirtyDaysAgo,
            },
         },
         select: {
            id: true,
            email: true,
         },
      });

      if (!pendingDeletions || pendingDeletions.length === 0) {
         logger.info("No pending account deletions older than 30 days found.");
         return { success: true, processed: 0, message: "No pending account deletions found" };
      }

      logger.info(`Found ${pendingDeletions.length} accounts to process for deletion.`);

      let processedCount = 0;

      for (const user of pendingDeletions) {
         try {
            await accountDeletionService.processAccountDeletion(user.id);
            processedCount++;
            logger.info(`Successfully processed automated deletion for user ID ${user.id}`);
         } catch (error: any) {
            // We log the error but don't break the loop so other accounts can still be processed
            logger.error(`Failed to process automated deletion for user ID ${user.id}:`, error);
         }
      }

      return {
         success: true,
         processed: processedCount,
         message: `Automated deletion job completed. Successfully processed ${processedCount}/${pendingDeletions.length} accounts.`,
      };
   } catch (error: any) {
      logger.error("Error running automated account deletion job:", error);
      throw error;
   }
}
