import prisma from "@/config/prisma";
import { Prisma, UserFeature } from "@prisma/client";
import { IUserFeatureRepository } from "../interfaces/repositories/user.feature.repository.interface";

export class UserFeatureRepository implements IUserFeatureRepository {
   async findByUserId(userId: number): Promise<UserFeature | null> {
      return prisma.userFeature.findUnique({ where: { userId } });
   }

   async create(data: Prisma.UserFeatureCreateInput): Promise<UserFeature> {
      return prisma.userFeature.create({ data });
   }

   async update(userId: number, data: Prisma.UserFeatureUpdateInput): Promise<UserFeature> {
      return prisma.userFeature.update({ where: { userId }, data });
   }

   async delete(userId: number): Promise<UserFeature> {
      return prisma.userFeature.delete({ where: { userId } });
   }
}
