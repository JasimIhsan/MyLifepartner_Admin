import { Prisma, User } from "@prisma/client";
import userRepository from "../repositories/user.repository";

class UserService {
   public async createUser(userData: Prisma.UserCreateInput): Promise<User> {
      if (await userRepository.findByEmail(userData.email)) {
         throw new Error(`User with email ${userData.email} already exists`);
      }
      return await userRepository.create(userData);
   }

   public async getUsers(): Promise<User[]> {
      return await userRepository.findAll();
   }

   public async getUserById(userId: number): Promise<User> {
      const user = await userRepository.findById(userId);
      if (!user) {
         throw new Error("User not found");
      }
      return user;
   }
}

export default new UserService();
