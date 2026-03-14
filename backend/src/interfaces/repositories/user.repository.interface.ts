import { Prisma, User } from "@prisma/client";

export interface IUserRepository {
   create(data: Prisma.UserCreateInput): Promise<User>;
   findAll(where?: Prisma.UserWhereInput, skip?: number, take?: number, include?: Prisma.UserInclude): Promise<{ users: User[]; total: number }>;
   findById(id: number): Promise<User | null>;
   findOnboardingStatusById(
      id: number
   ): Promise<{
      id: number;
      isDeleted: boolean;
      profile: {
         profileStatus: import("@prisma/client").ProfileStatus;
         hasCompletedBasicDetails: boolean;
         hasCompletedImageUpload: boolean;
         hasCompletedPartnerPreference: boolean;
         selfieStatus: import("@prisma/client").SelfieStatus | null;
      } | null;
   } | null>;
   findByEmail(email: string): Promise<User | null>;
   findByMobileNumber(mobileNumber: string): Promise<User | null>;
   update(id: number, data: Prisma.UserUpdateInput): Promise<User>;
   delete(id: number): Promise<User>;
}
