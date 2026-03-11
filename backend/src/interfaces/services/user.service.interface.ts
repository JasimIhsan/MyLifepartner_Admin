import { UserDto } from "@/dtos/user.dto";
import { Prisma } from "@prisma/client";

export interface IUserService {
   createUser(userData: Prisma.UserCreateInput): Promise<UserDto>;
   findOrCreateUser(email: string): Promise<UserDto>;
   findUserByEmail(email: string): Promise<UserDto | null>;
   getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<{ data: UserDto[]; total: number }>;
   getUserById(userId: number): Promise<UserDto>;
   updateUser(userId: number, updateData: Prisma.UserUpdateInput): Promise<UserDto>;
   toggleBlockUser(userId: number): Promise<UserDto>;
   deleteUser(userId: number): Promise<void>;
}
