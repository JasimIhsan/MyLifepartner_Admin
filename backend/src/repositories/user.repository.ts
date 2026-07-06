import prisma from "@/config/prisma";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserRepository, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { Prisma, SelfieStatus, User } from "@prisma/client";

type UserFilters = {
   searchQuery?: string;
   selfieStatus?: SelfieStatus;
};

type PaginatedUsers = {
   users: UserWithProfile[];
   total: number;
};

export class UserRepository implements IUserRepository {
   private static readonly STANDARD_INCLUDE = {
      profile: {
         include: {
            images: true,
         },
      },
      partnerPreference: true,
      userFeature: true,
   } satisfies Prisma.UserInclude;

   /**
    * Creates a user.
    *
    * @param data - User creation data.
    * @returns Created user with profile, partner preference, and feature details.
    */
   async create(data: CreateUserDto): Promise<UserWithProfile> {
      return prisma.user.create({
         data: {
            ...data,
            userFeature: {
               create: {},
            },
         },
         include: UserRepository.STANDARD_INCLUDE,
      });
   }

   /**
    * Gets users with filters and pagination.
    *
    * @param filters - User listing filters.
    * @param skip - Number of users to skip.
    * @param take - Number of users to fetch.
    * @returns Users and total matching count.
    */
   async findAll(filters?: UserFilters, skip?: number, take?: number): Promise<PaginatedUsers> {
      const where = this.buildUserWhereInput(filters);

      const [users, total] = await prisma.$transaction([
         prisma.user.findMany({
            where,
            include: UserRepository.STANDARD_INCLUDE,
            orderBy: {
               createdAt: "desc",
            },
            skip,
            take,
         }),
         prisma.user.count({
            where,
         }),
      ]);

      return {
         users,
         total,
      };
   }

   /**
    * Finds a user by ID.
    *
    * @param id - User ID.
    * @returns User with profile, partner preference, and feature details, or null if not found.
    */
   async findById(id: number): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: {
            id,
         },
         include: UserRepository.STANDARD_INCLUDE,
      });
   }

   /**
    * Finds onboarding status by user ID.
    *
    * @param id - User ID.
    * @returns User onboarding status, or null if not found.
    */
   async findOnboardingStatusById(id: number) {
      return prisma.user.findUnique({
         where: {
            id,
         },
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

   /**
    * Finds a user by email.
    *
    * @param email - User email.
    * @returns User with profile, partner preference, and feature details, or null if not found.
    */
   async findByEmail(email: string): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: {
            email,
         },
         include: UserRepository.STANDARD_INCLUDE,
      });
   }

   /**
    * Finds a user by mobile number.
    *
    * @param mobileNumber - User mobile number.
    * @returns User with profile, partner preference, and feature details, or null if not found.
    */
   async findByMobileNumber(mobileNumber: string): Promise<UserWithProfile | null> {
      return prisma.user.findUnique({
         where: {
            mobileNumber,
         },
         include: UserRepository.STANDARD_INCLUDE,
      });
   }

   /**
    * Updates a user.
    *
    * @param id - User ID.
    * @param data - User update data.
    * @returns Updated user with profile, partner preference, and feature details.
    */
   async update(id: number, data: UpdateUserDto): Promise<UserWithProfile> {
      const updateData = this.buildUserUpdateInput(data);

      return prisma.user.update({
         where: {
            id,
         },
         data: updateData,
         include: UserRepository.STANDARD_INCLUDE,
      });
   }

   /**
    * Soft deletes a user.
    *
    * @param id - User ID.
    * @returns Soft-deleted user.
    */
   async delete(id: number): Promise<User> {
      return prisma.user.update({
         where: {
            id,
         },
         data: {
            isDeleted: true,
         },
      });
   }

   /**
    * Builds user filter query.
    *
    * @param filters - User listing filters.
    * @returns Prisma user where input.
    */
   private buildUserWhereInput(filters?: UserFilters): Prisma.UserWhereInput {
      const where: Prisma.UserWhereInput = {
         isDeleted: false,
      };

      if (filters?.selfieStatus) {
         where.profile = {
            selfieStatus: filters.selfieStatus,
         };
      }

      const searchQuery = filters?.searchQuery?.trim();

      if (searchQuery) {
         where.OR = [
            {
               profile: {
                  name: {
                     contains: searchQuery,
                     mode: "insensitive",
                  },
               },
            },
            {
               email: {
                  contains: searchQuery,
                  mode: "insensitive",
               },
            },
            {
               mobileNumber: {
                  contains: searchQuery,
                  mode: "insensitive",
               },
            },
         ];
      }

      return where;
   }

   /**
    * Builds user update query.
    *
    * @param data - User update data.
    * @returns Prisma user update input.
    */
   private buildUserUpdateInput(data: UpdateUserDto): Prisma.UserUpdateInput {
      const { name, selfieStatus, ...userData } = data;

      const updateData: Prisma.UserUpdateInput = {
         ...userData,
      };

      const profileUpdateData: Prisma.ProfileUpdateWithoutUserInput = {};

      if (name !== undefined) {
         profileUpdateData.name = name;
      }

      if (selfieStatus !== undefined) {
         profileUpdateData.selfieStatus = selfieStatus;
      }

      if (Object.keys(profileUpdateData).length > 0) {
         updateData.profile = {
            update: profileUpdateData,
         };
      }

      return updateData;
   }
}
