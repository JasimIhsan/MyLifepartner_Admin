import { ReportPriority, ReportReason, ReportSource, ReportStatus, UserReport, Prisma } from "@prisma/client";

export type ReportWithDetails = Prisma.UserReportGetPayload<{
   include: {
      reporterUser: { select: { id: true; email: true; profile: { select: { name: true; profileStatus: true } } } };
      reportedUser: { select: { id: true; email: true; isBlocked: true; profile: { select: { name: true; profileStatus: true } } } };
      moderationLogs: true;
   };
}>;

export type ReportWithUsersProfile = Prisma.UserReportGetPayload<{
   include: {
      reporterUser: { include: { profile: { select: { name: true } } } };
      reportedUser: { include: { profile: { select: { name: true } } } };
   };
}>;

export interface IReportRepository {
   create(data: {
      reporterUserId: number;
      reportedUserId: number;
      reason: ReportReason;
      description?: string;
      source: ReportSource;
      relatedMessageId?: number;
      relatedConversationId?: number;
      evidenceScreenshots: string[];
   }): Promise<UserReport>;

   findRecentPendingReport(reporterUserId: number, reportedUserId: number): Promise<UserReport | null>;

   findByReporterId(userId: number): Promise<UserReport[]>;

   findAdminReports(where: Prisma.UserReportWhereInput, skip: number, take: number): Promise<[Prisma.UserReportGetPayload<{ include: { reporterUser: { select: { id: true; email: true } }; reportedUser: { select: { id: true; email: true } } } }>[], number]>;

   findByIdWithDetails(reportId: number): Promise<ReportWithDetails | null>;

   findByIdWithUsersProfile(reportId: number): Promise<ReportWithUsersProfile | null>;

   updateStatus(reportId: number, adminId: number, status: ReportStatus, priority?: ReportPriority, notes?: string): Promise<ReportWithUsersProfile>;
}
