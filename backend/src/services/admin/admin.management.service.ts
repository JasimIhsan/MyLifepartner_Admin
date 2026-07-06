import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { IAdminRepository } from "@/interfaces/repositories/admin.repository.interface";
import { IAdminManagementService } from "@/interfaces/services/admin.management.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { Admins, Role } from "@/interfaces/services/admin.management.service.interface";
import bcrypt from "bcrypt";

type AdminResponseDto = {
   id: number;
   username: string;
   role: Role;
   createdAt: Date;
   updatedAt: Date;
};

type DeleteAdminResponseDto = {
   success: boolean;
};

const PASSWORD_SALT_ROUNDS = 10;
const DEFAULT_ADMIN_PASSWORD = "defaultPassword123";

export class AdminManagementService implements IAdminManagementService {
   constructor(private readonly adminRepository: IAdminRepository) {}

   /**
    * Gets all admins.
    *
    * @returns Admins without password.
    */
   async getAllAdmins(): Promise<AdminResponseDto[]> {
      const admins = await this.adminRepository.findAll();

      return admins.map((admin) => this.toAdminResponseDto(admin as unknown as Admins));
   }

   /**
    * Gets admin by ID.
    *
    * @param id - Admin ID.
    * @returns Admin without password.
    */
   async getAdminById(id: number): Promise<AdminResponseDto> {
      const admin = await this.getRequiredAdmin(id);

      return this.toAdminResponseDto(admin as unknown as Admins);
   }

   /**
    * Creates an admin.
    *
    * @param data - Admin creation data.
    * @returns Created admin without password.
    */
   async createAdmin(data: CreateAdminDto): Promise<AdminResponseDto> {
      await this.ensureUsernameIsAvailable(data.username);

      const hashedPassword = await this.hashPassword(data.password ?? DEFAULT_ADMIN_PASSWORD);

      const admin = await this.adminRepository.create({
         username: data.username,
         password: hashedPassword,
         role: data.role,
      });

      return this.toAdminResponseDto(admin as unknown as Admins);
   }

   /**
    * Updates an admin.
    *
    * @param id - Admin ID.
    * @param data - Admin update data.
    * @returns Updated admin without password.
    */
   async updateAdmin(id: number, data: UpdateAdminDto): Promise<AdminResponseDto> {
      const existingAdmin = await this.getRequiredAdmin(id);

      if (data.username && data.username !== existingAdmin.username) {
         await this.ensureUsernameIsAvailable(data.username);
      }

      const updateData = await this.buildAdminUpdateData(data);
      const admin = await this.adminRepository.update(id, updateData);

      return this.toAdminResponseDto(admin as unknown as Admins);
   }

   /**
    * Deletes an admin.
    *
    * @param id - Admin ID.
    * @param currentAdminId - Current admin ID.
    * @returns Delete status.
    */
   async deleteAdmin(id: number, currentAdminId: number): Promise<DeleteAdminResponseDto> {
      const admin = await this.getRequiredAdmin(id);

      if (id === currentAdminId) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "You cannot delete your own account");
      }

      if (admin.role === Role.SUPER_ADMIN) {
         await this.ensureNotLastSuperAdmin();
      }

      await this.adminRepository.delete(id);

      return {
         success: true,
      };
   }

   /**
    * Gets required admin.
    *
    * @param id - Admin ID.
    * @returns Admin.
    */
   private async getRequiredAdmin(id: number): Promise<Admins> {
      const admin = await this.adminRepository.findById(id) as unknown as Admins | null;

      if (!admin) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Admin not found");
      }

      return admin;
   }

   /**
    * Checks username availability.
    *
    * @param username - Admin username.
    * @returns Nothing.
    */
   private async ensureUsernameIsAvailable(username: string): Promise<void> {
      const existingAdmin = await this.adminRepository.findByUsername(username);

      if (existingAdmin) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "Username already exists");
      }
   }

   /**
    * Builds admin update data.
    *
    * @param data - Admin update data.
    * @returns Admin update data.
    */
   private async buildAdminUpdateData(data: UpdateAdminDto): Promise<UpdateAdminDto> {
      const updateData: UpdateAdminDto = {};

      if (data.username) {
         updateData.username = data.username;
      }

      if (data.role) {
         updateData.role = data.role;
      }

      if (data.password) {
         updateData.password = await this.hashPassword(data.password);
      }

      return updateData;
   }

   /**
    * Checks last super admin deletion.
    *
    * @returns Nothing.
    */
   private async ensureNotLastSuperAdmin(): Promise<void> {
      const superAdminsCount = await this.adminRepository.countValidators(Role.SUPER_ADMIN);

      if (superAdminsCount <= 1) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Cannot delete the last super admin");
      }
   }

   /**
    * Hashes password.
    *
    * @param password - Plain password.
    * @returns Hashed password.
    */
   private async hashPassword(password: string): Promise<string> {
      return bcrypt.hash(password, PASSWORD_SALT_ROUNDS);
   }

   /**
    * Maps admin response.
    *
    * @param admin - Admin data.
    * @returns Admin without password.
    */
   private toAdminResponseDto(admin: Admins): AdminResponseDto {
      return {
         id: admin.id,
         username: admin.username,
         role: admin.role,
         createdAt: admin.createdAt,
         updatedAt: admin.updatedAt,
      };
   }
}
