import { NextFunction, Request, Response } from "express";
import env from "../config/env";
import logger from "../utils/logger";

interface HttpException extends Error {
   status?: number;
   message: string;
}

const errorMiddleware = (error: HttpException, req: Request, res: Response, next: NextFunction) => {
   try {
      const status: number = error.status || 500;
      const message: string = error.message || "Something went wrong";

      logger.error(`[${req.method}] ${req.path} >> StatusCode:: ${status}, Message:: ${message}`);

      res.status(status).json({
         success: false,
         message,
         stack: env.NODE_ENV === "development" ? error.stack : undefined,
      });
   } catch (error) {
      next(error);
   }
};

export default errorMiddleware;
