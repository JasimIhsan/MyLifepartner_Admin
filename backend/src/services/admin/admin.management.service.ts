import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { Role } from "@prisma/client";
import bcrypt from "bcrypt";
import { IAdminRepository } from "../../interfaces/repositories/admin.repository.interface";
import { IAdminManagementService } from "../../interfaces/services/admin.management.service.interface";

export class AdminManagementService implements IAdminManagementService {
   constructor(private adminRepository: IAdminRepository) {}

   /**
    * Retrieves a list of all administrators
    * @returns Array of admin objects omitting sensitive data like passwords
    */
   async getAllAdmins() {
      const admins = await this.adminRepository.findAll();
      return admins.map((admin) => ({
         id: admin.id,
         username: admin.username,
         role: admin.role as "ADMIN" | "SUPER_ADMIN",
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      }));
   }

   /**
    * Retrieves an administrator by their unique ID
    * @param id - The ID of the admin
    * @returns The admin object omitting sensitive data
    * @throws ApiError if admin is not found
    */
   async getAdminById(id: number) {
      const admin = await this.adminRepository.findById(id);

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }
      return {
         id: admin.id,
         username: admin.username,
         role: admin.role as "ADMIN" | "SUPER_ADMIN",
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   /**
    * Creates a new administrator
    * @param data - The DTO containing the new admin's details
    * @returns The created admin object omitting sensitive data
    * @throws ApiError if the username is already taken
    */
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
         role: data.role,
      });

      return {
         id: admin.id,
         username: admin.username,
         role: admin.role as "ADMIN" | "SUPER_ADMIN",
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   /**
    * Updates an existing administrator's details
    * @param id - The ID of the admin to update
    * @param data - The DTO containing the fields to update
    * @returns The updated admin object omitting sensitive data
    * @throws ApiError if admin not found or if the new username is already taken
    */
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

      const updateData: UpdateAdminDto = {};
      if (data.username) updateData.username = data.username;
      if (data.role) updateData.role = data.role;

      if (data.password) {
         updateData.password = await bcrypt.hash(data.password, 10);
      }

      const admin = await this.adminRepository.update(id, updateData);

      return {
         id: admin.id,
         username: admin.username,
         role: admin.role as "ADMIN" | "SUPER_ADMIN",
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }

   /**
    * Deletes an administrator
    * @param id - The ID of the admin to delete
    * @param currentAdminId - The ID of the admin performing the request to prevent self-deletion
    * @returns A success status object
    * @throws ApiError if admin not found, attempting self-deletion, or deleting the last super admin
    */
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
