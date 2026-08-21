import { IModerationRepository } from "@/interfaces/repositories/moderation.repository.interface";
import { IReportRepository } from "@/interfaces/repositories/report.repository.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";
import { ModerationActionLog, ModerationActionType, ReportPriority, ReportReason, ReportSource, ReportStatus, UserReport } from "@prisma/client";

export interface CreateReportDto {
   reporterUserId: number;
   reportedUserId: number;
   reason: ReportReason;
   description?: string;
   source: ReportSource;
   relatedMessageId?: number;
   relatedConversationId?: number;
}

export class ReportService {
   private readonly s3Service: IS3Service;
   private readonly emailService: IEmailService;
   private readonly reportRepository: IReportRepository;
   private readonly moderationRepository: IModerationRepository;

   constructor(s3Service: IS3Service, emailService: IEmailService, reportRepository: IReportRepository, moderationRepository: IModerationRepository) {
      this.s3Service = s3Service;
      this.emailService = emailService;
      this.reportRepository = reportRepository;
      this.moderationRepository = moderationRepository;
   }

   public async createReport(data: CreateReportDto, files: Express.Multer.File[]): Promise<UserReport> {
      const evidenceScreenshots: string[] = [];

      // Upload screenshots to S3
      if (files && files.length > 0) {
         for (const file of files) {
            try {
               const key = await this.s3Service.uploadToS3(file, `reports/${data.reportedUserId}`);
               evidenceScreenshots.push(key);
            } catch (error) {
               logger.error("Failed to upload report screenshot:", error);
            }
         }
      }

      // Check for duplicate recent reports from same user
      const existingReport = await this.reportRepository.findRecentPendingReport(data.reporterUserId, data.reportedUserId);

      if (existingReport) {
         throw new ApiError(400, "You have already reported this user recently. Your report is under review.");
      }

      const report = await this.reportRepository.create({
         reporterUserId: data.reporterUserId,
         reportedUserId: data.reportedUserId,
         reason: data.reason,
         description: data.description,
         source: data.source,
         relatedMessageId: data.relatedMessageId,
         relatedConversationId: data.relatedConversationId,
         evidenceScreenshots,
      });

      return report;
   }

   public async getUserSubmittedReports(userId: number): Promise<UserReport[]> {
      return this.reportRepository.findByReporterId(userId);
   }

   public async getAdminReports(filters: { status?: ReportStatus; priority?: ReportPriority; reason?: ReportReason; search?: string; page?: number; limit?: number }) {
      const page = filters.page || 1;
      const limit = filters.limit || 10;
      const skip = (page - 1) * limit;

      const where: any = {
         ...(filters.status && { status: filters.status }),
         ...(filters.priority && { priority: filters.priority }),
         ...(filters.reason && { reason: filters.reason }),
      };

      if (filters.search) {
         const searchStr = filters.search.trim();
         where.OR = [{ reporterUser: { email: { contains: searchStr, mode: "insensitive" } } }, { reportedUser: { email: { contains: searchStr, mode: "insensitive" } } }, { reporterUser: { profile: { name: { contains: searchStr, mode: "insensitive" } } } }, { reportedUser: { profile: { name: { contains: searchStr, mode: "insensitive" } } } }];

         // If the search string is a valid ID number, also search by IDs
         const searchNum = Number(searchStr);
         if (!isNaN(searchNum) && searchStr.length > 0) {
            where.OR.push({ id: searchNum });
            where.OR.push({ reporterUserId: searchNum });
            where.OR.push({ reportedUserId: searchNum });
         }
      }

      const [reports, total] = await this.reportRepository.findAdminReports(where, skip, limit);

      return { reports, total, page, limit, totalPages: Math.ceil(total / limit) };
   }

   public async getReportDetails(reportId: number) {
      const report = await this.reportRepository.findByIdWithDetails(reportId);

      if (!report) throw new ApiError(404, "Report not found");

      // Resolve S3 URLs for screenshots
      const resolvedScreenshots = await Promise.all(report.evidenceScreenshots.map((key: string) => this.s3Service.getPresignedUrl(key)));

      return { ...report, evidenceScreenshotsUrls: resolvedScreenshots };
   }

   public async updateReportStatus(reportId: number, adminId: number, status: ReportStatus, priority?: ReportPriority, notes?: string) {
      const updatedReport = await this.reportRepository.updateStatus(reportId, adminId, status, priority, notes);

      // Send email notification to reporter asynchronously
      this.emailService.sendReportStatusUpdateEmail(updatedReport.reporterUser.email, updatedReport.reporterUser.profile?.name || "User", updatedReport.reportedUser.profile?.name || "User", updatedReport.id, updatedReport.status, notes).catch((err) => logger.error("Failed to send report status update email", err));

      return updatedReport;
   }

   public async takeModerationAction(reportId: number, adminId: number, action: ModerationActionType, reason: string, notes?: string): Promise<ModerationActionLog> {
      const report = await this.reportRepository.findByIdWithUsersProfile(reportId);

      if (!report) throw new ApiError(404, "Report not found");

      const result = await this.moderationRepository.executeModerationActionTransaction(reportId, adminId, action, reason, report.reportedUserId, notes);

      // Send email notification to reporter asynchronously
      this.emailService.sendReportStatusUpdateEmail(report.reporterUser.email, report.reporterUser.profile?.name || "User", report.reportedUser.profile?.name || "User", report.id, ReportStatus.RESOLVED, notes).catch((err) => logger.error("Failed to send report status update email to reporter", err));

      // Send email notification to reported user
      let title = "";
      let message = "";
      if (action === ModerationActionType.WARNING) {
         title = "Official Warning";
         message = `We have received reports regarding your account. Reason: ${reason}. Please ensure you follow our community guidelines.`;
      } else if (action === ModerationActionType.TEMPORARY_SUSPENSION) {
         title = "Account Suspended";
         message = `Your account has been temporarily suspended for 14 days due to a violation of our community guidelines. Reason: ${reason}. You will not be able to log in during this period.`;
      } else if (action === ModerationActionType.PERMANENT_BAN) {
         title = "Account Permanently Banned";
         message = `Your account has been permanently banned due to a severe violation of our community guidelines. Reason: ${reason}.`;
      }

      if (title && message) {
         this.emailService.sendModerationEmail(report.reportedUser.email, report.reportedUser.profile?.name || "User", title, message).catch((err) => logger.error("Failed to send moderation email to reported user", err));
      }

      return result;
   }

   public async getUserModerationHistory(userId: number) {
      return this.moderationRepository.getUserModerationHistory(userId);
   }

   public async hasUnresolvedReportsAgainstUser(userId: number): Promise<boolean> {
      return this.reportRepository.hasUnresolvedReportsAgainstUser(userId);
   }
}
