import { ApiError } from "@/utils/ApiError";
import { NextFunction, Request, Response } from "express";
import { ZodError, ZodIssue, ZodTypeAny } from "zod";

export const validate = (schema: ZodTypeAny) => {
   return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
      try {
         await schema.parseAsync({
            body: req.body,
            query: req.query,
            params: req.params,
         });

         next();
      } catch (error) {
         if (error instanceof ZodError) {
            next(new ApiError(400, formatZodErrorMessage(error.issues), error.issues));
            return;
         }

         next(error);
      }
   };
};

/**
 * Formats Zod validation errors.
 *
 * @param issues - Zod validation issues.
 * @returns Formatted validation error message.
 */
const formatZodErrorMessage = (issues: ZodIssue[]): string => {
   return issues.map(formatZodIssue).join(", ");
};

/**
 * Formats a single Zod validation issue.
 *
 * @param issue - Zod validation issue.
 * @returns Formatted validation issue message.
 */
const formatZodIssue = (issue: ZodIssue): string => {
   const path = issue.path
      .join(".")
      .replace(/^body\./, "")
      .replace(/^query\./, "")
      .replace(/^params\./, "");

   return path ? `${path}: ${issue.message}` : issue.message;
};
