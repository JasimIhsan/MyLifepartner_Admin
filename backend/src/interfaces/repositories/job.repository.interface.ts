import { Job } from "@prisma/client";

export interface IJobRepository {
   findAll(search?: string): Promise<Job[]>;
   findByName(name: string): Promise<Job | null>;
   create(name: string): Promise<Job>;
}
