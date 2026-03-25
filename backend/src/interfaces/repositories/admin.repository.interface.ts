import { Admins, Prisma, Role } from "@prisma/client";

export interface IAdminRepository {
   findById(id: number): Promise<Admins | null>;
   findByUsername(username: string): Promise<Admins | null>;
   findAll(): Promise<Admins[]>;
   create(data: Prisma.AdminsCreateInput): Promise<Admins>;
   update(id: number, data: Prisma.AdminsUpdateInput): Promise<Admins>;
   delete(id: number): Promise<Admins>;
   countValidators(role?: Role): Promise<number>;
}

