import prisma from "@/config/prisma";
import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { Admins, Prisma, Role } from "@prisma/client";
import { IAdminRepository } from "../interfaces/repositories/admin.repository.interface";

export class AdminRepository implements IAdminRepository {
   /**
    * Finds an admin by ID.
    *
    * @param id - Admin ID.
    * @returns Admin, or null if not found.
    */
   async findById(id: number): Promise<Admins | null> {
      return prisma.admins.findUnique({
         where: {
            id,
         },
      });
   }

   /**
    * Finds an admin by username.
    *
    * @param username - Admin username.
    * @returns Admin, or null if not found.
    */
   async findByUsername(username: string): Promise<Admins | null> {
      return prisma.admins.findUnique({
         where: {
            username,
         },
      });
   }

   /**
    * Gets all admins.
    *
    * @returns List of admins.
    */
   async findAll(): Promise<Admins[]> {
      return prisma.admins.findMany({
         orderBy: {
            createdAt: "desc",
         },
      });
   }

   /**
    * Creates an admin.
    *
    * @param data - Admin creation data.
    * @returns Created admin.
    */
   async create(data: CreateAdminDto): Promise<Admins> {
      const createData: Prisma.AdminsCreateInput = {
         username: data.username,
         password: data.password ?? "",
         role: data.role,
      };

      return prisma.admins.create({
         data: createData,
      });
   }

   /**
    * Updates an admin.
    *
    * @param id - Admin ID.
    * @param data - Admin update data.
    * @returns Updated admin.
    */
   async update(id: number, data: UpdateAdminDto): Promise<Admins> {
      const updateData = this.buildAdminUpdateInput(data);

      return prisma.admins.update({
         where: {
            id,
         },
         data: updateData,
      });
   }

   /**
    * Deletes an admin.
    *
    * @param id - Admin ID.
    * @returns Deleted admin.
    */
   async delete(id: number): Promise<Admins> {
      return prisma.admins.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Counts admins by role.
    *
    * @param role - Admin role.
    * @returns Admin count.
    */
   async countValidators(role: Role = Role.SUPER_ADMIN): Promise<number> {
      return prisma.admins.count({
         where: {
            role,
         },
      });
   }

   /**
    * Builds admin update query.
    *
    * @param data - Admin update data.
    * @returns Prisma admin update input.
    */
   private buildAdminUpdateInput(data: UpdateAdminDto): Prisma.AdminsUpdateInput {
      const updateData: Prisma.AdminsUpdateInput = {};

      if (data.username !== undefined) {
         updateData.username = data.username;
      }

      if (data.role !== undefined) {
         updateData.role = data.role;
      }

      if (data.password !== undefined) {
         updateData.password = data.password;
      }

      return updateData;
   }
}
