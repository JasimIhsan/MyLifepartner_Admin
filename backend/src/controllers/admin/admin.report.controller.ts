import { ReportService } from "@/services/report.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { ModerationActionType, ReportPriority, ReportReason, ReportStatus } from "@prisma/client";
import { Request, Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

export class AdminReportController {
   constructor(private readonly reportService: ReportService) {}

   /**
    * @route GET /api/v1/admin/reports
    * @desc Fetch all reports with pagination and filters
    */
   public getReports = asyncHandler(async (req: Request, res: Response) => {
      const { status, priority, reason, page, limit, search } = req.query;
      const filters = {
         ...(status && { status: status as ReportStatus }),
         ...(priority && { priority: priority as ReportPriority }),
         ...(reason && { reason: reason as ReportReason }),
         ...(search && { search: search as string | undefined }),
         page: page ? parseInt(page as string) : 1,
         limit: limit ? parseInt(limit as string) : 10,
      };

      const result = await this.reportService.getAdminReports(filters);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Reports fetched successfully"));
   });

   /**
    * @route GET /api/v1/admin/reports/:id
    * @desc Get report details by ID
    */
   public getReportById = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      const report = await this.reportService.getReportDetails(parseInt(id as string));
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, report, "Report details fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/reports/:id/status
    * @desc Update report status and priority
    */
   public updateReportStatus = asyncHandler(async (req: AuthRequest, res: Response) => {
      const adminId = req.user!.id;
      const { id } = req.params;
      const { status, priority, notes } = req.body;

      const report = await this.reportService.updateReportStatus(parseInt(id as string), adminId, status as ReportStatus, priority as ReportPriority, notes);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.MODERATION,
         action: "UPDATE_REPORT_STATUS",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Updated report ID: ${id} status to ${status}`,
         newValue: { status, priority, notes },
         entityType: "UserReport",
         entityId: id as string,
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, report, "Report status updated successfully"));
   });

   /**
    * @route POST /api/v1/admin/reports/:id/action
    * @desc Take moderation action against a user for a report
    */
   public takeModerationAction = asyncHandler(async (req: AuthRequest, res: Response) => {
      const adminId = req.user!.id;
      const { id } = req.params;
      const { action, reason, notes } = req.body;

      if (!action || !reason) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Action and reason are required");
      }

      const result = await this.reportService.takeModerationAction(parseInt(id as string), adminId, action as ModerationActionType, reason, notes);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.MODERATION,
         action: "TAKE_MODERATION_ACTION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `Took moderation action: ${action} on report ID: ${id}`,
         newValue: { action, reason, notes },
         entityType: "UserReport",
         entityId: id as string,
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Moderation action taken successfully"));
   });

   /**
    * @route GET /api/v1/admin/reports/users/:userId/history
    * @desc Get moderation history for a user
    */
   public getUserHistory = asyncHandler(async (req: Request, res: Response) => {
      const { userId } = req.params;
      const history = await this.reportService.getUserModerationHistory(parseInt(userId as string));
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, history, "User moderation history fetched"));
   });
}
