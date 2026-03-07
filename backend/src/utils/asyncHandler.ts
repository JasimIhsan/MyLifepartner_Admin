import { NextFunction, Request, Response } from "express";

const asyncHandler = <T extends Request = Request>(requestHandler: (req: T, res: Response, next: NextFunction) => Promise<unknown>) => {
   return (req: Request, res: Response, next: NextFunction) => {
      Promise.resolve(requestHandler(req as unknown as T, res, next)).catch((err) => next(err));
   };
};

export { asyncHandler };
