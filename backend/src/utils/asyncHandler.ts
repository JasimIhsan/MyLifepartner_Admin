import { NextFunction, Request, Response } from "express";

type AsyncRequestHandler<TRequest extends Request = Request> = (req: TRequest, res: Response, next: NextFunction) => Promise<unknown>;

const asyncHandler = <TRequest extends Request = Request>(requestHandler: AsyncRequestHandler<TRequest>) => {
   return (req: Request, res: Response, next: NextFunction): void => {
      Promise.resolve(requestHandler(req as TRequest, res, next)).catch(next);
   };
};

export { asyncHandler };
