import { ReportService } from "@/services/report.service";
import { S3Service } from "@/services/s3.service";
import { ApiResponse } from "@/utils/ApiResponse";
import { ModerationActionType, ReportPriority, ReportReason, ReportStatus } from "@prisma/client";
import { NextFunction, Request, Response } from "express";

import { ReportRepository } from "@/repositories/report.repository";
import { ModerationRepository } from "@/repositories/moderation.repository";
import { EmailService } from "@/services/email.service";

const s3Service = new S3Service();
const emailService = new EmailService(s3Service);
const reportRepository = new ReportRepository();
const moderationRepository = new ModerationRepository();
const reportService = new ReportService(s3Service, emailService, reportRepository, moderationRepository);

export const getReports = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const { status, priority, reason, page, limit, search } = req.query;
      const filters = {
         ...(status && { status: status as ReportStatus }),
         ...(priority && { priority: priority as ReportPriority }),
         ...(reason && { reason: reason as ReportReason }),
         ...(search && { search: search as string }),
         page: page ? parseInt(page as string) : 1,
         limit: limit ? parseInt(limit as string) : 10,
      };

      const result = await reportService.getAdminReports(filters);
      res.status(200).json(new ApiResponse(200, result, "Reports fetched successfully"));
   } catch (error) {
      next(error);
   }
};

export const getReportById = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const { id } = req.params;
      const report = await reportService.getReportDetails(parseInt(id as string));
      res.status(200).json(new ApiResponse(200, report, "Report details fetched successfully"));
   } catch (error) {
      next(error);
   }
};

export const updateReportStatus = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const adminId = req.user!.id;
      const { id } = req.params;
      const { status, priority, notes } = req.body;

      const report = await reportService.updateReportStatus(parseInt(id as string), adminId, status as ReportStatus, priority as ReportPriority, notes);

      res.status(200).json(new ApiResponse(200, report, "Report status updated successfully"));
   } catch (error) {
      next(error);
   }
};

export const takeModerationAction = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const adminId = req.user!.id;
      const { id } = req.params;
      const { action, reason, notes } = req.body;

      if (!action || !reason) {
         return res.status(400).json({ success: false, message: "Action and reason are required" });
      }

      const result = await reportService.takeModerationAction(parseInt(id as string), adminId, action as ModerationActionType, reason, notes);

      res.status(200).json(new ApiResponse(200, result, "Moderation action taken successfully"));
   } catch (error) {
      next(error);
   }
};

export const getUserHistory = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const { userId } = req.params;
      const history = await reportService.getUserModerationHistory(parseInt(userId as string));
      res.status(200).json(new ApiResponse(200, history, "User moderation history fetched"));
   } catch (error) {
      next(error);
   }
};
