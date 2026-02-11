import { NextFunction, Request, Response } from "express";

const asyncHandler = (requestHandler: (req: Request, res: Response, next: NextFunction) => Promise<unknown>) => {
   return (req: Request, res: Response, next: NextFunction) => {
      Promise.resolve(requestHandler(req, res, next)).catch((err) => next(err));
   };
};

export { asyncHandler };
