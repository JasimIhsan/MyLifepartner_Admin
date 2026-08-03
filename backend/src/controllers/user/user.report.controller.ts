import { NextFunction, Request, Response } from "express";
import { ReportService } from "@/services/report.service";
import { S3Service } from "@/services/s3.service";
import { ApiResponse } from "@/utils/ApiResponse";
import { ReportReason, ReportSource } from "@prisma/client";

import { ReportRepository } from "@/repositories/report.repository";
import { ModerationRepository } from "@/repositories/moderation.repository";
import { EmailService } from "@/services/email.service";

const s3Service = new S3Service();
const emailService = new EmailService(s3Service);
const reportRepository = new ReportRepository();
const moderationRepository = new ModerationRepository();
const reportService = new ReportService(s3Service, emailService, reportRepository, moderationRepository);

export const submitReport = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const reporterUserId = req.user!.id;
      const { reportedUserId, reason, description, source, relatedMessageId, relatedConversationId } = req.body;

      if (!reportedUserId || !reason || !source) {
         return res.status(400).json({ success: false, message: "Missing required fields" });
      }

      const files = req.files as Express.Multer.File[];

      const report = await reportService.createReport({
         reporterUserId,
         reportedUserId: parseInt(reportedUserId),
         reason: reason as ReportReason,
         description,
         source: source as ReportSource,
         relatedMessageId: relatedMessageId ? parseInt(relatedMessageId) : undefined,
         relatedConversationId: relatedConversationId ? parseInt(relatedConversationId) : undefined,
      }, files);

      res.status(201).json(new ApiResponse(201, report, "Report submitted successfully"));
   } catch (error) {
      next(error);
   }
};

export const getUserReports = async (req: Request, res: Response, next: NextFunction) => {
   try {
      const userId = req.user!.id;
      const reports = await reportService.getUserSubmittedReports(userId);
      res.status(200).json(new ApiResponse(200, reports, "Reports fetched successfully"));
   } catch (error) {
      next(error);
   }
};
