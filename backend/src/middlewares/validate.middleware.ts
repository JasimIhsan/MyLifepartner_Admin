import { ApiError } from "@/utils/ApiError";
import { NextFunction, Request, Response } from "express";
import { ZodError, ZodTypeAny } from "zod";

export const validate = (schema: ZodTypeAny) => {
   return async (req: Request, res: Response, next: NextFunction) => {
      try {
         await schema.parseAsync({
            body: req.body,
            query: req.query,
            params: req.params,
         });
         return next();
      } catch (error) {
         if (error instanceof ZodError) {
            // Extract the first error message for a clean response
            const err = error.issues
               .map((e) => {
                  const path = e.path
                     .join(".")
                     .replace(/^body\./, "")
                     .replace(/^query\./, "")
                     .replace(/^params\./, "");
                  return `${path}: ${e.message}`;
               })
               .join(", ");
            const apiError = new ApiError(400, err, error.issues);
            return next(apiError);
         }
         return next(error);
      }
   };
};
