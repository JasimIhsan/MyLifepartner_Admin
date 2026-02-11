import { NextFunction, Request, Response } from "express";
import env from "../config/env";
import { ApiError } from "../utils/ApiError";
import logger from "../utils/logger";

const errorMiddleware = (err: Error & { statusCode?: number; errors?: unknown[] }, req: Request, res: Response, next: NextFunction) => {
   let error: ApiError;

   if (err instanceof ApiError) {
      error = err;
   } else {
      const statusCode = err.statusCode || 500;
      const message = err.message || "Something went wrong";
      error = new ApiError(statusCode, message, err.errors || [], err.stack);
   }

   const response = {
      ...error,
      message: error.message,
      success: false,
      ...(env.NODE_ENV === "development" ? { stack: error.stack } : {}),
   };

   logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${error.statusCode}, Message:: ${error.message}`);

   return res.status(error.statusCode).json(response);
};

export default errorMiddleware;
