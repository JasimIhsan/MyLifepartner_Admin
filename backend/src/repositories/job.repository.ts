import prisma from "@/config/prisma";
import { Job } from "@prisma/client";
import { IJobRepository } from "../interfaces/repositories/job.repository.interface";

export class JobRepository implements IJobRepository {
   async findAll(search?: string): Promise<Job[]> {
      const whereClause = search
         ? { name: { contains: search, mode: "insensitive" as const } }
         : {};

      return prisma.job.findMany({
         where: whereClause,
         orderBy: { name: "asc" },
      });
   }

   async getPopularJobs(limit: number): Promise<Job[]> {
      const popular = await prisma.profile.groupBy({
         by: ["jobId"],
         where: { jobId: { not: null } },
         _count: { jobId: true },
         orderBy: { _count: { jobId: "desc" } },
         take: limit,
      });

      const jobIds = popular.map((p) => p.jobId as number);
      if (jobIds.length === 0) {
         return prisma.job.findMany({
            take: limit,
         });
      }

      const jobs = await prisma.job.findMany({
         where: { id: { in: jobIds } },
      });

      // Maintain order sorted by popularity
      return jobIds.map((id) => jobs.find((j) => j.id === id)!).filter(Boolean);
   }

   async findByName(name: string): Promise<Job | null> {
      return prisma.job.findFirst({
         where: { name: { equals: name, mode: "insensitive" } },
      });
   }

   async create(name: string): Promise<Job> {
      return prisma.job.create({
         data: { name },
      });
   }
}
