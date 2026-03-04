import { UserDto, toUserDto } from "@/dtos/user.dto";
import userRepository from "@/repositories/user.repository";
import { ApiError } from "@/utils/ApiError";
import { Prisma } from "@prisma/client";

class UserService {
   async createUser(userData: Prisma.UserCreateInput): Promise<UserDto> {
      if (await userRepository.findByMobileNumber(userData.mobileNumber)) {
         throw new ApiError(409, `User with mobile number ${userData.mobileNumber} already exists`);
      }
      return toUserDto(await userRepository.create(userData));
   }

   async findOrCreateUser(mobileNumber: string): Promise<UserDto> {
      const user = await userRepository.findByMobileNumber(mobileNumber);
      if (!user) {
         return toUserDto(await userRepository.create({ mobileNumber }));
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

      const { users, total } = await userRepository.findAll(where, skip, take, { profile: { include: { images: true } } });
      return { data: users.map((u) => toUserDto(u)), total };
   }

   async getUserById(userId: number): Promise<UserDto> {
      const user = await userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      return toUserDto(user);
   }

   async updateUser(userId: number, updateData: Prisma.UserUpdateInput): Promise<UserDto> {
      console.log(`👉 updateData : `, updateData);
      const user = await userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      if (updateData.email) {
         const existingUser = await userRepository.findByEmail(updateData.email as string);
         if (existingUser && existingUser.id !== userId) {
            throw new ApiError(409, "Email is already in use by another account");
         }
      }

      const updatedUser = await userRepository.update(userId, updateData);
      return toUserDto(updatedUser);
   }

   async toggleBlockUser(userId: number): Promise<UserDto> {
      const user = await userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      const updatedUser = await userRepository.update(userId, { isBlocked: !user.isBlocked });
      return toUserDto(updatedUser);
   }

   async deleteUser(userId: number): Promise<void> {
      const user = await userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      await userRepository.update(userId, { isDeleted: true });
   }
}

export default new UserService();
