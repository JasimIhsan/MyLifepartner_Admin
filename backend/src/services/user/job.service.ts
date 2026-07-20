import { IJobRepository } from "@/interfaces/repositories/job.repository.interface";
import { IJobService } from "@/interfaces/services/job.service.interface";
import { Job } from "@prisma/client";

export class JobService implements IJobService {
   constructor(private readonly jobRepository: IJobRepository) {}

   async searchJobs(search?: string): Promise<Job[]> {
      return this.jobRepository.findAll(search);
   }

   async getPopularJobs(limit: number = 10): Promise<Job[]> {
      return this.jobRepository.getPopularJobs(limit);
   }

   async getOrCreateJob(name: string): Promise<Job> {
      const trimmedName = name.trim();
      const existingJob = await this.jobRepository.findByName(trimmedName);
      if (existingJob) {
         return existingJob;
      }
      return this.jobRepository.create(trimmedName);
   }
}
