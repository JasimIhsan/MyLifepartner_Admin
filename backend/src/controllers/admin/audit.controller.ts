import { Request, Response } from "express";
import prisma from "@/config/prisma";

export class AdminAuditController {
   public async getAuditLogs(req: Request, res: Response): Promise<void> {
      try {
         const { page = 1, limit = 20, module, action, status, severity, actorType, source, userId, entityType, entityId, correlationId, search } = req.query;
         const parsedPage = parseInt(page as string, 10) || 1;
         const parsedLimit = parseInt(limit as string, 10) || 20;

         const where: any = {};

         if (module) where.module = module;
         if (action) where.action = action;
         if (status) where.status = status;
         if (severity) where.severity = severity;
         if (actorType) where.actorType = actorType;
         if (source) where.source = source;
         if (userId) where.userId = parseInt(userId as string, 10);
         if (entityType) where.entityType = entityType;
         if (entityId) where.entityId = entityId;
         if (correlationId) where.correlationId = correlationId;

         if (search) {
            where.OR = [
               { message: { contains: search as string, mode: "insensitive" } },
               { correlationId: { contains: search as string, mode: "insensitive" } },
               { transactionId: { contains: search as string, mode: "insensitive" } },
               { revenueCatEventId: { contains: search as string, mode: "insensitive" } },
            ];
         }

         const [total, logs] = await Promise.all([
            prisma.auditLog.count({ where }),
            prisma.auditLog.findMany({
               where,
               skip: (parsedPage - 1) * parsedLimit,
               take: parsedLimit,
               orderBy: { createdAt: "desc" },
               include: {
                  user: { select: { id: true, email: true, mobileNumber: true, profile: { select: { name: true } } } },
                  admin: { select: { id: true, username: true } },
               },
            }),
         ]);

         res.status(200).json({
            success: true,
            data: logs,
            pagination: {
               total,
               page: parsedPage,
               limit: parsedLimit,
               totalPages: Math.ceil(total / parsedLimit),
            },
         });
      } catch (error) {
         res.status(500).json({ success: false, message: "Internal Server Error" });
      }
   }

   public async getAuditLogById(req: Request, res: Response): Promise<void> {
      try {
         const { id } = req.params;
         const log = await prisma.auditLog.findUnique({
            where: { id: parseInt(id as string, 10) },
            include: {
               user: { select: { id: true, email: true, profile: { select: { name: true } } } },
               admin: { select: { id: true, username: true } },
            },
         });

         if (!log) {
            res.status(404).json({ success: false, message: "Audit log not found" });
            return;
         }

         res.status(200).json({ success: true, data: log });
      } catch (error) {
         res.status(500).json({ success: false, message: "Internal Server Error" });
      }
   }

   public async getAuditLogTimeline(req: Request, res: Response): Promise<void> {
      try {
         const { id } = req.params;
         const log = await prisma.auditLog.findUnique({
            where: { id: parseInt(id as string, 10) },
            select: { correlationId: true, transactionId: true },
         });

         if (!log) {
            res.status(404).json({ success: false, message: "Audit log not found" });
            return;
         }

         const where: any = { OR: [] };
         if (log.correlationId) where.OR.push({ correlationId: log.correlationId });
         if (log.transactionId) where.OR.push({ transactionId: log.transactionId });

         if (where.OR.length === 0) {
            res.status(200).json({ success: true, data: [] });
            return;
         }

         const timeline = await prisma.auditLog.findMany({
            where,
            orderBy: { createdAt: "asc" },
            include: {
               user: { select: { id: true, profile: { select: { name: true } } } },
               admin: { select: { id: true, username: true } },
            },
         });

         res.status(200).json({ success: true, data: timeline });
      } catch (error) {
         res.status(500).json({ success: false, message: "Internal Server Error" });
      }
   }

   public async getUserAuditLogs(req: Request, res: Response): Promise<void> {
      try {
         const { userId } = req.params;
         const { page = 1, limit = 20 } = req.query;
         const parsedPage = parseInt(page as string, 10) || 1;
         const parsedLimit = parseInt(limit as string, 10) || 20;

         const where = { userId: parseInt(userId as string, 10) };

         const [total, logs] = await Promise.all([
            prisma.auditLog.count({ where }),
            prisma.auditLog.findMany({
               where,
               skip: (parsedPage - 1) * parsedLimit,
               take: parsedLimit,
               orderBy: { createdAt: "desc" },
            }),
         ]);

         res.status(200).json({
            success: true,
            data: logs,
            pagination: {
               total,
               page: parsedPage,
               limit: parsedLimit,
               totalPages: Math.ceil(total / parsedLimit),
            },
         });
      } catch (error) {
         res.status(500).json({ success: false, message: "Internal Server Error" });
      }
   }
}

export const adminAuditController = new AdminAuditController();
