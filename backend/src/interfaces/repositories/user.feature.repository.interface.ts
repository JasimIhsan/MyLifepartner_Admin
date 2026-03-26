import { Prisma, UserFeature } from "@prisma/client";

export interface IUserFeatureRepository {
   findByUserId(userId: number): Promise<UserFeature | null>;
   create(data: Prisma.UserFeatureCreateInput): Promise<UserFeature>;
   update(userId: number, data: Prisma.UserFeatureUpdateInput): Promise<UserFeature>;
   delete(userId: number): Promise<UserFeature>;
}
