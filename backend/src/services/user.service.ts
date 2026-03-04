import { UserDto, toUserDto } from "@/dtos/user.dto";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { ApiError } from "@/utils/ApiError";
import { Prisma, User } from "@prisma/client";

export class UserService implements IUserService {
   constructor(private userRepository: IUserRepository) {}

   async createUser(userData: Prisma.UserCreateInput): Promise<UserDto> {
      if (await this.userRepository.findByMobileNumber(userData.mobileNumber)) {
         throw new ApiError(409, `User with mobile number ${userData.mobileNumber} already exists`);
      }
      return toUserDto(await this.userRepository.create(userData));
   }

   async findOrCreateUser(mobileNumber: string): Promise<UserDto> {
      const user = await this.userRepository.findByMobileNumber(mobileNumber);
      if (!user) {
         return toUserDto(await this.userRepository.create({ mobileNumber }));
      }
      return toUserDto(user);
   }

   async getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<{ data: UserDto[]; total: number }> {
      const where: Prisma.UserWhereInput = { isDeleted: false };

      if (selfieStatus) {
         where.profile = { selfieStatus: selfieStatus as import("@prisma/client").SelfieStatus };
      }

      if (searchQuery) {
         where.OR = [{ profile: { name: { contains: searchQuery, mode: "insensitive" } } }, { email: { contains: searchQuery, mode: "insensitive" } }, { mobileNumber: { contains: searchQuery, mode: "insensitive" } }];
      }

      const skip = page && limit ? (page - 1) * limit : undefined;
      const take = limit ? limit : undefined;

      const { users, total } = await this.userRepository.findAll(where, skip, take, { profile: { include: { images: true } } });
      return { data: users.map((u: User) => toUserDto(u)), total };
   }

   async getUserById(userId: number): Promise<UserDto> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      return toUserDto(user);
   }

   async updateUser(userId: number, updateData: Prisma.UserUpdateInput): Promise<UserDto> {
      console.log(`👉 updateData : `, updateData);
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      if (updateData.email) {
         const existingUser = await this.userRepository.findByEmail(updateData.email as string);
         if (existingUser && existingUser.id !== userId) {
            throw new ApiError(409, "Email is already in use by another account");
         }
      }

      const updatedUser = await this.userRepository.update(userId, updateData);
      return toUserDto(updatedUser);
   }

   async toggleBlockUser(userId: number): Promise<UserDto> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      const updatedUser = await this.userRepository.update(userId, { isBlocked: !user.isBlocked });
      return toUserDto(updatedUser);
   }

   async deleteUser(userId: number): Promise<void> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      await this.userRepository.update(userId, { isDeleted: true });
   }
}
