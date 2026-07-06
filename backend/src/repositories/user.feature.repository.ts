import prisma from "@/config/prisma";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { Prisma, UserFeature } from "@prisma/client";

export class UserFeatureRepository implements IUserFeatureRepository {
   /**
    * Finds a user feature record by user ID.
    *
    * @param userId - The unique ID of the user.
    * @returns The user feature record if found, otherwise null.
    */
   async findByUserId(userId: number): Promise<UserFeature | null> {
      return prisma.userFeature.findUnique({
         where: {
            userId,
         },
      });
   }

   /**
    * Creates a new user feature record.
    *
    * @param data - The user feature creation data.
    * @returns The newly created user feature record.
    */
   async create(data: Prisma.UserFeatureCreateInput): Promise<UserFeature> {
      return prisma.userFeature.create({
         data,
      });
   }

   /**
    * Updates a user feature record by user ID.
    *
    * @param userId - The unique ID of the user.
    * @param data - The user feature update data.
    * @returns The updated user feature record.
    */
   async update(userId: number, data: Prisma.UserFeatureUpdateInput): Promise<UserFeature> {
      return prisma.userFeature.update({
         where: {
            userId,
         },
         data,
      });
   }

   /**
    * Deletes a user feature record by user ID.
    *
    * @param userId - The unique ID of the user.
    * @returns The deleted user feature record.
    */
   async delete(userId: number): Promise<UserFeature> {
      return prisma.userFeature.delete({
         where: {
            userId,
         },
      });
   }
}
