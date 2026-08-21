import prisma from "@/config/prisma";
import { IReportRepository, ReportWithDetails, ReportWithUsersProfile } from "@/interfaces/repositories/report.repository.interface";
import { Prisma, ReportPriority, ReportReason, ReportSource, ReportStatus, UserReport } from "@prisma/client";

export class ReportRepository implements IReportRepository {
   async create(data: { reporterUserId: number; reportedUserId: number; reason: ReportReason; description?: string; source: ReportSource; relatedMessageId?: number; relatedConversationId?: number; evidenceScreenshots: string[] }): Promise<UserReport> {
      return prisma.userReport.create({ data });
   }

   async findRecentPendingReport(reporterUserId: number, reportedUserId: number): Promise<UserReport | null> {
      return prisma.userReport.findFirst({
         where: {
            reporterUserId,
            reportedUserId,
            status: { in: [ReportStatus.PENDING, ReportStatus.UNDER_REVIEW] },
            createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }, // Last 24 hours
         },
      });
   }

   async findByReporterId(userId: number): Promise<UserReport[]> {
      return prisma.userReport.findMany({
         where: { reporterUserId: userId },
         orderBy: { createdAt: "desc" },
      });
   }

   async findAdminReports(where: Prisma.UserReportWhereInput, skip: number, take: number): Promise<[Prisma.UserReportGetPayload<{ include: { reporterUser: { select: { id: true; email: true } }; reportedUser: { select: { id: true; email: true } } } }>[], number]> {
      const reports = await prisma.userReport.findMany({
         where,
         include: {
            reporterUser: { select: { id: true, email: true } },
            reportedUser: { select: { id: true, email: true } },
         },
         orderBy: { createdAt: "desc" },
         skip,
         take,
      });
      const total = await prisma.userReport.count({ where });
      return [reports, total];
   }

   async findByIdWithDetails(reportId: number): Promise<ReportWithDetails | null> {
      return prisma.userReport.findUnique({
         where: { id: reportId },
         include: {
            reporterUser: { select: { id: true, email: true, profile: { select: { name: true, profileStatus: true } } } },
            reportedUser: { select: { id: true, email: true, isBanned: true, isSuspended: true, profile: { select: { name: true, profileStatus: true } } } },
            moderationLogs: true,
         },
      });
   }

   async findByIdWithUsersProfile(reportId: number): Promise<ReportWithUsersProfile | null> {
      return prisma.userReport.findUnique({
         where: { id: reportId },
         include: {
            reporterUser: { include: { profile: { select: { name: true } } } },
            reportedUser: { include: { profile: { select: { name: true } } } },
         },
      });
   }

   async updateStatus(reportId: number, adminId: number, status: ReportStatus, priority?: ReportPriority, notes?: string): Promise<ReportWithUsersProfile> {
      return prisma.userReport.update({
         where: { id: reportId },
         data: {
            status,
            assignedAdminId: adminId,
            ...(priority && { priority }),
            ...(notes && { adminNotes: notes }),
         },
         include: {
            reporterUser: {
               include: {
                  profile: { select: { name: true } },
               },
            },
            reportedUser: {
               include: {
                  profile: { select: { name: true } },
               },
            },
         },
      });
   }

   async hasUnresolvedReportsAgainstUser(userId: number): Promise<boolean> {
      const report = await prisma.userReport.findFirst({
         where: {
            reportedUserId: userId,
            status: { in: [ReportStatus.PENDING, ReportStatus.UNDER_REVIEW] },
         },
      });
      return !!report;
   }
}
