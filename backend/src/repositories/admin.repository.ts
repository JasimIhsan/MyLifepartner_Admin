import prisma from "@/config/prisma";
import { Admin, Prisma, Role } from "@prisma/client";
import { IAdminRepository } from "../interfaces/repositories/admin.repository.interface";

export class AdminRepository implements IAdminRepository {
   async findById(id: number): Promise<Admin | null> {
      return prisma.admin.findUnique({ where: { id } });
   }

   async findByUsername(username: string): Promise<Admin | null> {
      return prisma.admin.findUnique({ where: { username } });
   }

   async findAll(): Promise<Admin[]> {
      return prisma.admin.findMany({
         orderBy: { createdAt: "desc" },
      });
   }

   async create(data: Prisma.AdminCreateInput): Promise<Admin> {
      return prisma.admin.create({ data });
   }

   async update(id: number, data: Prisma.AdminUpdateInput): Promise<Admin> {
      return prisma.admin.update({
         where: { id },
         data,
      });
   }

   async delete(id: number): Promise<Admin> {
      return prisma.admin.delete({
         where: { id },
      });
   }

   async countValidators(role: Role = "SUPER_ADMIN" as Role): Promise<number> {
      return prisma.admin.count({
         where: { role },
      });
   }
}
