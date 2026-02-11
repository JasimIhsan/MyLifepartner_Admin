import userRepository from "@/repositories/user.repository";
import { ApiError } from "@/utils/ApiError";
import { Prisma, User } from "@prisma/client";

class UserService {
   async createUser(userData: Prisma.UserCreateInput): Promise<User> {
      if (await userRepository.findByMobileNumber(userData.mobileNumber)) {
         throw new ApiError(409, `User with mobile number ${userData.mobileNumber} already exists`);
      }
      return await userRepository.create(userData);
   }

   async findOrCreateUser(mobileNumber: string): Promise<User> {
      const user = await userRepository.findByMobileNumber(mobileNumber);
      if (!user) {
         return await userRepository.create({ mobileNumber });
      }
      return user;
   }

   async getUsers(): Promise<User[]> {
      return await userRepository.findAll();
   }

   async getUserById(userId: number): Promise<User> {
      const user = await userRepository.findById(userId);
      if (!user) {
         throw new ApiError(404, "User not found");
      }
      return user;
   }
}

export default new UserService();
