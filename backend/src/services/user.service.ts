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

   async getUsers(): Promise<UserDto[]> {
      const users = await userRepository.findAll();
      return users.map((u) => toUserDto(u));
   }

   async getUserById(userId: number): Promise<UserDto> {
      const user = await userRepository.findById(userId);
      if (!user) {
         throw new ApiError(404, "User not found");
      }
      return toUserDto(user);
   }

   async updateUser(userId: number, updateData: Prisma.UserUpdateInput): Promise<UserDto> {
      console.log(`👉 updateData : `, updateData);
      const user = await userRepository.findById(userId);
      if (!user) {
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
}

export default new UserService();
