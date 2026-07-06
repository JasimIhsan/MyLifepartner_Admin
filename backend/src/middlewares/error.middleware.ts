import env from "@/config/env";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";
import { NextFunction, Request, Response } from "express";

type ErrorWithStatus = Error & {
   statusCode?: number;
   errors?: unknown[];
};

const DEFAULT_ERROR_MESSAGE = "Something went wrong. Please try again later.";

const errorMiddleware = (err: ErrorWithStatus, req: Request, res: Response, _next: NextFunction): Response => {
   const error = normalizeError(err);
   const originalMessage = err.message || "Unknown error";

   logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${error.statusCode}, Message:: ${originalMessage}`);

   if (!(err instanceof ApiError) && err.stack) {
      logger.error(`Unhandled Error Stack: ${err.stack}`);
   }

   return res.status(error.statusCode).json({
      ...error,
      message: error.message,
      success: false,
      ...(env.NODE_ENV === "development" && {
         stack: error.stack,
      }),
   });
};

/**
 * Normalizes thrown errors into ApiError.
 *
 * @param err - Thrown error.
 * @returns Normalized API error.
 */
const normalizeError = (err: ErrorWithStatus): ApiError => {
   if (err instanceof ApiError) {
      return err;
   }

   return new ApiError(err.statusCode ?? 500, DEFAULT_ERROR_MESSAGE, err.errors ?? [], err.stack);
};

export default errorMiddleware;
