import { Request, Response } from "express";
import { BlockService } from "../../services/block.service";
import { AuthRequest } from "../../types/AuthRequest";

import { asyncHandler } from "../../utils/asyncHandler";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

export class UserBlockController {
  constructor(private blockService: BlockService) {}

  blockUser = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const blockerId = req.user!.id;
      const blockedId = parseInt(req.params.userId as string, 10);

      if (isNaN(blockedId)) {
        return res.status(400).json({ success: false, message: "Invalid user ID" });
      }

      await this.blockService.blockUser(blockerId, blockedId);

      await auditService.log({
        userId: blockerId,
        actorType: ActorType.USER,
        module: AuditModule.MODERATION,
        action: "BLOCK_USER",
        status: AuditStatus.SUCCESS,
        severity: AuditSeverity.INFO,
        message: `User blocked user ID: ${blockedId}`,
        newValue: { blockedUserId: blockedId },
        entityType: "User",
        entityId: blockedId.toString(),
        source: AuditSource.API,
      });

      return res.status(200).json({ success: true, message: "User blocked successfully" });
    } catch (error: any) {
      return res.status(400).json({ success: false, message: error.message });
    }
  });

  unblockUser = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const blockerId = req.user!.id;
      const blockedId = parseInt(req.params.userId as string, 10);

      if (isNaN(blockedId)) {
        return res.status(400).json({ success: false, message: "Invalid user ID" });
      }

      const success = await this.blockService.unblockUser(blockerId, blockedId);
      if (success) {
        await auditService.log({
          userId: blockerId,
          actorType: ActorType.USER,
          module: AuditModule.MODERATION,
          action: "UNBLOCK_USER",
          status: AuditStatus.SUCCESS,
          severity: AuditSeverity.INFO,
          message: `User unblocked user ID: ${blockedId}`,
          newValue: { unblockedUserId: blockedId },
          entityType: "User",
          entityId: blockedId.toString(),
          source: AuditSource.API,
        });

        return res.status(200).json({ success: true, message: "User unblocked successfully" });
      } else {
        return res.status(404).json({ success: false, message: "Block not found" });
      }
    } catch (error: any) {
      return res.status(500).json({ success: false, message: error.message });
    }
  });

  getBlockedUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
    try {
      const blockerId = req.user!.id;
      const blockedUsers = await this.blockService.getBlockedUsers(blockerId);
      return res.status(200).json({ success: true, data: blockedUsers });
    } catch (error: any) {
      return res.status(500).json({ success: false, message: error.message });
    }
  });
}
