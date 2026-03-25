import prisma from "@/config/prisma";
import { Admins, Prisma, Role } from "@prisma/client";
import { IAdminRepository } from "../interfaces/repositories/admin.repository.interface";

export class AdminRepository implements IAdminRepository {
   async findById(id: number): Promise<Admins | null> {
      return prisma.admins.findUnique({ where: { id } });
   }

   async findByUsername(username: string): Promise<Admins | null> {
      return prisma.admins.findUnique({ where: { username } });
   }

   async findAll(): Promise<Admins[]> {
      return prisma.admins.findMany({
         orderBy: { createdAt: "desc" },
      });
   }

   async create(data: Prisma.AdminsCreateInput): Promise<Admins> {
      return prisma.admins.create({ data });
   }

   async update(id: number, data: Prisma.AdminsUpdateInput): Promise<Admins> {
      return prisma.admins.update({
         where: { id },
         data,
      });
   }

   async delete(id: number): Promise<Admins> {
      return prisma.admins.delete({
         where: { id },
      });
   }

   async countValidators(role: Role = "SUPER_ADMIN" as Role): Promise<number> {
      return prisma.admins.count({
         where: { role },
      });
   }
}

