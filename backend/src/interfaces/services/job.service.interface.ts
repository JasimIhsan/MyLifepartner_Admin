import { Job } from "@prisma/client";

export interface IJobService {
   searchJobs(search?: string): Promise<Job[]>;
   getOrCreateJob(name: string): Promise<Job>;
}
