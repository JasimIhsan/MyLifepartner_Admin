import prisma from '@/config/prisma';
import { auditContextStorage } from '@/middlewares/auditContext.middleware';
import { sanitizeForAudit } from '@/utils/sanitizer.util';
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource, Prisma } from '@prisma/client';
import logger from '@/utils/logger';

export interface AuditLogPayload {
  userId?: number;
  adminId?: number;
  actorType: ActorType;
  module: AuditModule;
  action: string;
  entityType?: string;
  entityId?: string;
  status: AuditStatus;
  severity: AuditSeverity;
  message: string;
  oldValue?: any;
  newValue?: any;
  metadata?: any;
  transactionId?: string;
  revenueCatEventId?: string;
  source: AuditSource;
  route?: string;
  method?: string;
  statusCode?: number;
}

export class AuditService {
  /**
   * Logs an event asynchronously. Uses the current AsyncLocalStorage context for 
   * correlationId, IP, userAgent, etc.
   * Does NOT throw errors to prevent interrupting the main request flow.
   */
  public async log(payload: AuditLogPayload, tx?: Prisma.TransactionClient): Promise<void> {
    try {
      const context = auditContextStorage.getStore();
      const prismaClient = tx || prisma;

      // Ensure fields are sanitized
      const sanitizedOldValue = payload.oldValue ? sanitizeForAudit(payload.oldValue) : undefined;
      const sanitizedNewValue = payload.newValue ? sanitizeForAudit(payload.newValue) : undefined;
      const sanitizedMetadata = payload.metadata ? sanitizeForAudit(payload.metadata) : undefined;

      const logData = {
        userId: payload.userId || context?.userId,
        adminId: payload.adminId || context?.adminId,
        actorType: payload.actorType,
        module: payload.module,
        action: payload.action,
        entityType: payload.entityType,
        entityId: payload.entityId,
        status: payload.status,
        severity: payload.severity,
        message: payload.message,
        oldValue: sanitizedOldValue ?? Prisma.DbNull,
        newValue: sanitizedNewValue ?? Prisma.DbNull,
        metadata: sanitizedMetadata ?? Prisma.DbNull,
        correlationId: context?.correlationId,
        transactionId: payload.transactionId,
        revenueCatEventId: payload.revenueCatEventId,
        source: payload.source,
        route: payload.route,
        method: payload.method,
        statusCode: payload.statusCode,
        ipAddress: context?.ipAddress,
        userAgent: context?.userAgent,
      };

      await prismaClient.auditLog.create({
        data: logData,
      });

    } catch (error) {
      // We must not throw here unless strictly transactional and caller expects it
      // but we should log to our server logger (e.g. Winston/Pino)
      logger.error('Failed to write audit log:', error);
      if (tx) {
        // If part of a transaction, throw so it rolls back, as audit is critical for tx
        throw error;
      }
    }
  }
}

export const auditService = new AuditService();
