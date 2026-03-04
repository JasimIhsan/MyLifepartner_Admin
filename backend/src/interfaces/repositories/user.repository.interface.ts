import { Prisma, User } from "@prisma/client";

export interface IUserRepository {
   create(data: Prisma.UserCreateInput): Promise<User>;
   findAll(where?: Prisma.UserWhereInput, skip?: number, take?: number, include?: Prisma.UserInclude): Promise<{ users: User[]; total: number }>;
   findById(id: number): Promise<User | null>;
   findByEmail(email: string): Promise<User | null>;
   findByMobileNumber(mobileNumber: string): Promise<User | null>;
   update(id: number, data: Prisma.UserUpdateInput): Promise<User>;
   delete(id: number): Promise<User>;
}
