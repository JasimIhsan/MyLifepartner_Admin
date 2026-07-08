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
