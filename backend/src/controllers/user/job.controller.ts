import { IJobService } from "@/interfaces/services/job.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { z } from "zod";

const createJobSchema = z.object({
   name: z.string().min(1, "Job name is required").max(100, "Job name is too long"),
});

export class JobController {
   constructor(private readonly jobService: IJobService) {}

   public getJobs = asyncHandler(async (req: Request, res: Response) => {
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;
      const jobs = await this.jobService.searchJobs(search);

      return res
         .status(HTTP_STATUS.OK)
         .json(new ApiResponse(HTTP_STATUS.OK, jobs, "Jobs retrieved successfully"));
   });

   public getPopularJobs = asyncHandler(async (req: Request, res: Response) => {
      const limit = req.query.limit ? parseInt(req.query.limit as string, 10) : 10;
      const jobs = await this.jobService.getPopularJobs(limit);

      return res
         .status(HTTP_STATUS.OK)
         .json(new ApiResponse(HTTP_STATUS.OK, jobs, "Popular jobs retrieved successfully"));
   });

   public createJob = asyncHandler(async (req: Request, res: Response) => {
      const parsed = createJobSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const job = await this.jobService.getOrCreateJob(parsed.data.name);

      return res
         .status(HTTP_STATUS.CREATED)
         .json(new ApiResponse(HTTP_STATUS.CREATED, job, "Job processed successfully"));
   });
}
