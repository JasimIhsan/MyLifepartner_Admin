import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { Role } from "@prisma/client";
import bcrypt from "bcrypt";
import { IAdminRepository } from "../../interfaces/repositories/admin.repository.interface";
import { IAdminManagementService } from "../../interfaces/services/admin.management.service.interface";

export class AdminManagementService implements IAdminManagementService {
   constructor(private adminRepository: IAdminRepository) {}

   async getAllAdmins() {
      const admins = await this.adminRepository.findAll();
      return admins.map((admin) => ({
         id: admin.id,
         username: admin.username,
         role: admin.role,
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      }));
   }

   async getAdminById(id: number) {
      const admin = await this.adminRepository.findById(id);

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }
      return {
         id: admin.id,
         username: admin.username,
         role: admin.role,
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   async createAdmin(data: CreateAdminDto) {
      const existingAdmin = await this.adminRepository.findByUsername(data.username);

      if (existingAdmin) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "Username already exists");
      }

      const passwordToHash = data.password || "defaultPassword123";
      const hashedPassword = await bcrypt.hash(passwordToHash, 10);

      const admin = await this.adminRepository.create({
         username: data.username,
         password: hashedPassword,
         role: data.role as Role,
      });

      return {
         id: admin.id,
         username: admin.username,
         role: admin.role,
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   async updateAdmin(id: number, data: UpdateAdminDto) {
      const existingAdmin = await this.adminRepository.findById(id);

      if (!existingAdmin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }

      if (data.username && data.username !== existingAdmin.username) {
         const usernameTaken = await this.adminRepository.findByUsername(data.username);
         if (usernameTaken) {
            throw new ApiError(HTTP_STATUS.CONFLICT, "Username already exists");
         }
      }

      const updateData: any = {};
      if (data.username) updateData.username = data.username;
      if (data.role) updateData.role = data.role as Role;

      if (data.password) {
         updateData.password = await bcrypt.hash(data.password, 10);
      }

      const admin = await this.adminRepository.update(id, updateData);

      return {
         id: admin.id,
         username: admin.username,
         role: admin.role,
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   async deleteAdmin(id: number, currentAdminId: number) {
      const admin = await this.adminRepository.findById(id);

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }

      if (id === currentAdminId) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "You cannot delete your own account");
      }

      if (admin.role === ("SUPER_ADMIN" as Role)) {
         const superAdminsCount = await this.adminRepository.countValidators("SUPER_ADMIN" as Role);

         if (superAdminsCount <= 1) {
            throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Cannot delete the last super admin");
         }
      }

      await this.adminRepository.delete(id);

      return { success: true };
   }
}
