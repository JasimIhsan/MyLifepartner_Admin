import { PartnerPreference, Prisma, Profile, User, UserFeature } from "@prisma/client";

export type UserWithProfile = User & { 
   profile: (Profile & { images: { id: number; imageUrl: string; isPrimary: boolean }[] }) | null;
   partnerPreference?: PartnerPreference | null;
   userFeature?: UserFeature | null;
};

export interface IUserRepository {
   create(data: Prisma.UserCreateInput): Promise<UserWithProfile>;
   findAll(where?: Prisma.UserWhereInput, skip?: number, take?: number, include?: Prisma.UserInclude): Promise<{ users: User[]; total: number }>;
   findById(id: number): Promise<UserWithProfile | null>;
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
   findByEmail(email: string): Promise<UserWithProfile | null>;
   findByMobileNumber(mobileNumber: string): Promise<UserWithProfile | null>;
   update(id: number, data: Prisma.UserUpdateInput): Promise<UserWithProfile>;
   delete(id: number): Promise<User>;
}
