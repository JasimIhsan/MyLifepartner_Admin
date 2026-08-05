import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { ReportReason, ReportSource } from "@prisma/client";
import { Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

import { ReportService } from "@/services/report.service";

export class UserReportController {
   constructor(private readonly reportService: ReportService) {}

   /**
    * @route POST /api/v1/reports
    * @desc Submit a new user report
    */
   public submitReport = asyncHandler(async (req: AuthRequest, res: Response) => {
      const reporterUserId = req.user!.id;
      const { reportedUserId, reason, description, source, relatedMessageId, relatedConversationId } = req.body;

      if (!reportedUserId || !reason || !source) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Missing required fields");
      }

      const files = req.files as Express.Multer.File[];

      const report = await this.reportService.createReport(
         {
            reporterUserId,
            reportedUserId: parseInt(reportedUserId),
            reason: reason as ReportReason,
            description,
            source: source as ReportSource,
            relatedMessageId: relatedMessageId ? parseInt(relatedMessageId) : undefined,
            relatedConversationId: relatedConversationId ? parseInt(relatedConversationId) : undefined,
         },
         files
      );

      await auditService.log({
         userId: reporterUserId,
         actorType: ActorType.USER,
         module: AuditModule.MODERATION,
         action: "SUBMIT_REPORT",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `User submitted a report against user ID: ${reportedUserId}`,
         newValue: { reason, description, source, reportedUserId },
         entityType: "UserReport",
         entityId: report.id.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, report, "Report submitted successfully"));
   });

   /**
    * @route GET /api/v1/reports
    * @desc Get all reports submitted by the authenticated user
    */
   public getUserReports = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.user!.id;
      const reports = await this.reportService.getUserSubmittedReports(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, reports, "Reports fetched successfully"));
   });
}
