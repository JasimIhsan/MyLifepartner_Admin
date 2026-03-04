import prisma from "@/config/prisma";
import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import bcrypt from "bcrypt";

class AdminManagementService {
   async getAllAdmins() {
      const admins = await prisma.admin.findMany({
         select: {
            id: true,
            username: true,
            role: true,
            createdAt: true,
            updatedAt: true,
         },
         orderBy: {
            createdAt: "desc",
         },
      });
      return admins;
   }

   async getAdminById(id: number) {
      const admin = await prisma.admin.findUnique({
         where: { id },
         select: {
            id: true,
            username: true,
            role: true,
            createdAt: true,
            updatedAt: true,
         },
      });

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }
      return admin;
   }

   async createAdmin(data: CreateAdminDto) {
      const existingAdmin = await prisma.admin.findUnique({
         where: { username: data.username },
      });

      if (existingAdmin) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "Username already exists");
      }

      const passwordToHash = data.password || "defaultPassword123";
      const hashedPassword = await bcrypt.hash(passwordToHash, 10);

      const admin = await prisma.admin.create({
         data: {
            username: data.username,
            password: hashedPassword,
            role: data.role as import("@prisma/client").Role,
         },
         select: {
            id: true,
            username: true,
            role: true,
            createdAt: true,
            updatedAt: true,
         },
      });

      return admin;
   }

   async updateAdmin(id: number, data: UpdateAdminDto) {
      const existingAdmin = await prisma.admin.findUnique({
         where: { id },
      });

      if (!existingAdmin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }

      if (data.username && data.username !== existingAdmin.username) {
         const usernameTaken = await prisma.admin.findUnique({
            where: { username: data.username },
         });
         if (usernameTaken) {
            throw new ApiError(HTTP_STATUS.CONFLICT, "Username already exists");
         }
      }

      const updateData: import("@prisma/client").Prisma.AdminUpdateInput = {};
      if (data.username) updateData.username = data.username;
      if (data.role) updateData.role = data.role as import("@prisma/client").Role;

      if (data.password) {
         updateData.password = await bcrypt.hash(data.password, 10);
      }

      const admin = await prisma.admin.update({
         where: { id },
         data: updateData,
         select: {
            id: true,
            username: true,
            role: true,
            createdAt: true,
            updatedAt: true,
         },
      });

      return admin;
   }

   async deleteAdmin(id: number, currentAdminId: number) {
      const admin = await prisma.admin.findUnique({
         where: { id },
      });

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }

      if (id === currentAdminId) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "You cannot delete your own account");
      }

      if (admin.role === ("SUPER_ADMIN" as import("@prisma/client").Role)) {
         const superAdminsCount = await prisma.admin.count({
            where: { role: "SUPER_ADMIN" as import("@prisma/client").Role },
         });

         if (superAdminsCount <= 1) {
            throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Cannot delete the last super admin");
         }
      }

      await prisma.admin.delete({
         where: { id },
      });

      return { success: true };
   }
}

export default new AdminManagementService();
