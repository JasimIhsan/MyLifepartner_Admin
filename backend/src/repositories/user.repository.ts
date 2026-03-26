import prisma from "@/config/prisma";
import { Prisma, User } from "@prisma/client";
import { IUserRepository, UserWithProfile } from "../interfaces/repositories/user.repository.interface";

export class UserRepository implements IUserRepository {
   private static readonly STANDARD_INCLUDE: Prisma.UserInclude = {
      profile: { include: { images: true } },
      partnerPreference: true,
      userFeature: true,
   };

   async create(data: Prisma.UserCreateInput): Promise<UserWithProfile> {
      return prisma.user.create({
         data: {
            ...data,
            userFeature: data.userFeature || { create: {} },
         },
         include: UserRepository.STANDARD_INCLUDE,
      }) as unknown as Promise<UserWithProfile>;
   }

   async findAll(where?: Prisma.UserWhereInput, skip?: number, take?: number, include?: Prisma.UserInclude): Promise<{ users: User[]; total: number }> {
      const [users, total] = await prisma.$transaction([
         prisma.user.findMany({
            where,
            include: { ...include, partnerPreference: true },
            orderBy: { createdAt: "desc" },
            skip,
            take,
         }),
         prisma.user.count({ where }),
      ]);
      return { users, total };
   }

   async findById(id: number): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: { id },
         include: UserRepository.STANDARD_INCLUDE,
      }) as unknown as Promise<UserWithProfile | null>;
   }

   async findOnboardingStatusById(id: number) {
      return prisma.user.findUnique({
         where: { id },
         select: {
            id: true,
            isDeleted: true,
            profile: {
               select: {
                  profileStatus: true,
                  hasCompletedBasicDetails: true,
                  hasCompletedPartnerPreference: true,
                  hasCompletedImageUpload: true,
                  selfieStatus: true,
               },
            },
         },
      });
   }

   async findByEmail(email: string): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: { email },
         include: UserRepository.STANDARD_INCLUDE,
      }) as unknown as Promise<UserWithProfile | null>;
   }

   async findByMobileNumber(mobileNumber: string): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: { mobileNumber },
         include: UserRepository.STANDARD_INCLUDE,
      }) as unknown as Promise<UserWithProfile | null>;
   }

   async update(id: number, data: Prisma.UserUpdateInput): Promise<UserWithProfile> {
      return prisma.user.update({
         where: { id },
         data,
         include: UserRepository.STANDARD_INCLUDE,
      }) as unknown as Promise<UserWithProfile>;
   }

   async delete(id: number): Promise<User> {
      return prisma.user.delete({ where: { id } });
   }
}
