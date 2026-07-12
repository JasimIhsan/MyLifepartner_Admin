import env from "@/config/env";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";
import { NextFunction, Request, Response } from "express";
import multer from "multer";

type ErrorWithStatus = Error & {
   statusCode?: number;
   errors?: unknown[];
};

const DEFAULT_ERROR_MESSAGE = "Something went wrong. Please try again later.";

const errorMiddleware = (err: ErrorWithStatus, req: Request, res: Response, _next: NextFunction): Response => {
   const error = normalizeError(err);
   const originalMessage = err.message || "Unknown error";

   logger.error(`[${req.method}] ${req.originalUrl} >> StatusCode:: ${error.statusCode}, Message:: ${originalMessage}`);

   if (env.NODE_ENV === "development" && error.stack) {
      logger.error(`Error Stack: ${error.stack}`);
   }

   return res.status(error.statusCode).json({
      statusCode: error.statusCode,
      data: error.data,
      message: error.message,
      success: false,
      errors: error.errors,
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

   if (err instanceof multer.MulterError) {
      if (err.code === "LIMIT_FILE_SIZE") {
         return new ApiError(400, "File size limit exceeded. Maximum file size allowed is 20MB.", [], err.stack);
      }
      return new ApiError(400, err.message, [], err.stack);
   }

   return new ApiError(err.statusCode ?? 500, DEFAULT_ERROR_MESSAGE, err.errors ?? [], err.stack);
};

export default errorMiddleware;
