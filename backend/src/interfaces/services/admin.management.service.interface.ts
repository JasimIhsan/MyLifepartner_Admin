import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";

export interface IAdminManagementService {
   getAllAdmins(): Promise<{ id: number; username: string; role: string; createdAt: Date; updatedAt: Date }[]>;
   getAdminById(id: number): Promise<{ id: number; username: string; role: string; createdAt: Date; updatedAt: Date }>;
   createAdmin(data: CreateAdminDto): Promise<{ id: number; username: string; role: string; createdAt: Date; updatedAt: Date }>;
   updateAdmin(id: number, data: UpdateAdminDto): Promise<{ id: number; username: string; role: string; createdAt: Date; updatedAt: Date }>;
   deleteAdmin(id: number, currentAdminId: number): Promise<{ success: boolean }>;
}
