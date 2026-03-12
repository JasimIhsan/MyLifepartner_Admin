import prisma from "@/config/prisma";
import { Prisma, User } from "@prisma/client";
import { IUserRepository } from "../interfaces/repositories/user.repository.interface";

export class UserRepository implements IUserRepository {
   async create(data: Prisma.UserCreateInput): Promise<User> {
      return prisma.user.create({ data });
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

   async findById(id: number): Promise<User | null> {
      return prisma.user.findUnique({ where: { id }, include: { profile: { include: { images: true } }, partnerPreference: true } });
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

   async findByEmail(email: string): Promise<User | null> {
      return prisma.user.findUnique({ where: { email }, include: { profile: { include: { images: true } }, partnerPreference: true } });
   }

   async findByMobileNumber(mobileNumber: string): Promise<User | null> {
      return prisma.user.findUnique({ where: { mobileNumber }, include: { profile: { include: { images: true } }, partnerPreference: true } });
   }

   async update(id: number, data: Prisma.UserUpdateInput): Promise<User> {
      return prisma.user.update({ where: { id }, data, include: { profile: { include: { images: true } }, partnerPreference: true } });
   }

   async delete(id: number): Promise<User> {
      return prisma.user.delete({ where: { id } });
   }
}
