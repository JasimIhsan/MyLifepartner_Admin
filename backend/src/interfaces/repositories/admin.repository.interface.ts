import { Admins, Role } from "@prisma/client";
import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";

export interface IAdminRepository {
   findById(id: number): Promise<Admins | null>;
   findByUsername(username: string): Promise<Admins | null>;
   findAll(): Promise<Admins[]>;
   create(data: CreateAdminDto): Promise<Admins>;
   update(id: number, data: UpdateAdminDto): Promise<Admins>;
   delete(id: number): Promise<Admins>;
   countValidators(role?: Role): Promise<number>;
}

