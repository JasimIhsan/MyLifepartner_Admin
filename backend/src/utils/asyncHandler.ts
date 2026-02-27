import { NextFunction, Request, Response } from "express";

const asyncHandler = <T = Request>(requestHandler: (req: T, res: Response, next: NextFunction) => Promise<unknown>) => {
   return (req: Request, res: Response, next: NextFunction) => {
      Promise.resolve(requestHandler(req as any, res, next)).catch((err) => next(err));
   };
};

export { asyncHandler };
