import prisma from "@/config/prisma";
import { IModerationRepository } from "@/interfaces/repositories/moderation.repository.interface";
import { ModerationActionLog, ModerationActionType, ReportStatus } from "@prisma/client";

export class ModerationRepository implements IModerationRepository {
   async executeModerationActionTransaction(reportId: number, adminId: number, action: ModerationActionType, reason: string, reportedUserId: number, notes?: string): Promise<ModerationActionLog> {
      return prisma.$transaction(async (tx) => {
         // Create moderation log
         const log = await tx.moderationActionLog.create({
            data: {
               userId: reportedUserId,
               reportId,
               adminId,
               action,
               reason,
               notes,
            },
         });

         // Update report
         await tx.userReport.update({
            where: { id: reportId },
            data: {
               status: ReportStatus.RESOLVED,
               resolution: reason,
               actionTaken: action,
               actionTakenAt: new Date(),
               actionTakenBy: adminId,
               assignedAdminId: adminId,
            },
         });

         // Execute action
         if (action === ModerationActionType.PERMANENT_BAN || action === ModerationActionType.TEMPORARY_SUSPENSION) {
            await tx.user.update({
               where: { id: reportedUserId },
               data: { isBlocked: true },
            });
         }

         return log;
      });
   }

   async getUserModerationHistory(userId: number): Promise<(ModerationActionLog & { admin: { id: number; username: string | null } })[]> {
      return prisma.moderationActionLog.findMany({
         where: { userId },
         include: { admin: { select: { id: true, username: true } } },
         orderBy: { createdAt: "desc" },
      });
   }
}
