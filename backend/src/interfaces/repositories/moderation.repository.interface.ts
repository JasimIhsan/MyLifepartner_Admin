import { ModerationActionLog, ModerationActionType } from "@prisma/client";

export interface IModerationRepository {
   executeModerationActionTransaction(
      reportId: number,
      adminId: number,
      action: ModerationActionType,
      reason: string,
      reportedUserId: number,
      notes?: string
   ): Promise<ModerationActionLog>;

   getUserModerationHistory(userId: number): Promise<
      (ModerationActionLog & { admin: { id: number; username: string | null } })[]
   >;
}
