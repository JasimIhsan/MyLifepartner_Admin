import { NextFunction, Request, Response } from "express";
import env from "../config/env";
import { ApiError } from "../utils/ApiError";
import logger from "../utils/logger";

const errorMiddleware = (err: Error & { statusCode?: number; errors?: unknown[] }, req: Request, res: Response, next: NextFunction) => {
   let error: ApiError;

   // Capture original error message for server logging
   const originalMessage = err.message || "Unknown error";

   if (err instanceof ApiError) {
      error = err;
   } else {
      const statusCode = err.statusCode || 500;
      // Obfuscate the message sent to the client
      const message = "Something went wrong. Please try again later.";
      error = new ApiError(statusCode, message, err.errors || [], err.stack);
   }

   const response = {
      ...error,
      message: error.message,
      success: false,
      ...(env.NODE_ENV === "development" ? { stack: error.stack } : {}),
   };

   // Log the actual unhandled error message for debugging purposes
   logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${error.statusCode}, Message:: ${originalMessage}`);

   if (!(err instanceof ApiError) && err.stack) {
      logger.error(`Unhandled Error Stack: ${err.stack}`);
   }

   return res.status(error.statusCode).json(response);
};

export default errorMiddleware;
