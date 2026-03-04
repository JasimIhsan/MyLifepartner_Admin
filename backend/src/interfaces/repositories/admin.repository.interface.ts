import { Admin, Prisma, Role } from "@prisma/client";

export interface IAdminRepository {
   findById(id: number): Promise<Admin | null>;
   findByUsername(username: string): Promise<Admin | null>;
   findAll(): Promise<Admin[]>;
   create(data: Prisma.AdminCreateInput): Promise<Admin>;
   update(id: number, data: Prisma.AdminUpdateInput): Promise<Admin>;
   delete(id: number): Promise<Admin>;
   countValidators(role?: Role): Promise<number>;
}
