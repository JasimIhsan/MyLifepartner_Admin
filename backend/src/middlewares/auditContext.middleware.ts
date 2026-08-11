import { AsyncLocalStorage } from "async_hooks";
import { NextFunction, Request, Response } from "express";
import { v4 as uuidv4 } from "uuid";

export interface AuditContext {
   correlationId: string;
   ipAddress?: string;
   userAgent?: string;
   userId?: number;
   adminId?: number;
}

export const auditContextStorage = new AsyncLocalStorage<AuditContext>();

export const auditContextMiddleware = (req: Request, res: Response, next: NextFunction) => {
   // Use existing header if passed from another microservice/frontend or generate a new one
   const correlationId = (req.headers["x-correlation-id"] as string) || uuidv4();

   // Also expose to response so caller knows the request ID
   res.setHeader("x-correlation-id", correlationId);

   const context: AuditContext = {
      correlationId,
      ipAddress: (req.headers["x-forwarded-for"] as string) || req.socket.remoteAddress || "",
      userAgent: req.headers["user-agent"],
   };

   auditContextStorage.run(context, () => {
      next();
   });
};
