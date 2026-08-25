import prisma from "@/config/prisma";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserRepository, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { Prisma, SelfieStatus, SubscriptionStatus, User } from "@prisma/client";

const ACCESS_GRANTING_SUBSCRIPTION_STATUSES = [SubscriptionStatus.ACTIVE, SubscriptionStatus.CANCELLED_PENDING_EXPIRY, SubscriptionStatus.BILLING_ISSUE, SubscriptionStatus.GRACE_PERIOD];

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
            job: true,
         },
      },
      partnerPreference: true,
      userFeature: true,
      privacySettings: true,
      subscriptions: {
         where: {
            status: {
               in: ACCESS_GRANTING_SUBSCRIPTION_STATUSES,
            },
         },
         include: {
            plan: {
               select: {
                  id: true,
                  name: true,
                  price: true,
               },
            },
         },
         orderBy: {
            createdAt: "desc",
         },
         take: 1,
      },
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
            ...this.buildUserCreateInput(data),
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
    * Finds all suspended users.
    */
   async findSuspendedUsers(): Promise<UserWithProfile[]> {
      return prisma.user.findMany({
         where: {
            isSuspended: true,
         },
         include: UserRepository.STANDARD_INCLUDE,
         orderBy: {
            suspendedAt: "desc",
         },
      });
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
    * Finds the minimal user state needed for feature-access decisions.
    */
   async findFeatureAccessStatusById(id: number) {
      return prisma.user.findUnique({
         where: {
            id,
         },
         select: {
            id: true,
            isFoundingMember: true,
            isBanned: true,
            isSuspended: true,
            isDeleted: true,
            isDeleteRequested: true,
            deleteRequestStatus: true,
         },
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
    * Finds a user by provider and providerUserId.
    */
   async findByProviderId(provider: string, providerUserId: string): Promise<UserWithProfile | null> {
      const socialAccount = await prisma.socialAccount.findUnique({
         where: {
            provider_providerUserId: {
               provider,
               providerUserId,
            },
         },
         select: {
            userId: true,
         },
      });

      if (!socialAccount) return null;

      return this.findById(socialAccount.userId);
   }

   /**
    * Upserts a social account record linking a user to a social auth provider.
    */
   async upsertSocialAccount(userId: number, provider: string, providerUserId: string): Promise<void> {
      await prisma.socialAccount.upsert({
         where: {
            provider_providerUserId: {
               provider,
               providerUserId,
            },
         },
         update: {
            userId,
         },
         create: {
            userId,
            provider,
            providerUserId,
         },
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
    * Updates founding-member status.
    */
   async updateFoundingMemberStatus(id: number, isFoundingMember: boolean, foundingMemberSince: Date | null): Promise<UserWithProfile> {
      return prisma.user.update({
         where: {
            id,
         },
         data: {
            isFoundingMember,
            foundingMemberSince,
         },
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
    * Clears all device tokens for a user.
    */
   async clearDeviceTokens(userId: number): Promise<void> {
      await prisma.deviceToken.deleteMany({
         where: { userId },
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
         ];
      }

      return where;
   }

   /**
    * Builds user create query.
    *
    * @param data - User create data.
    * @returns Prisma user create input.
    */
   private buildUserCreateInput(data: CreateUserDto): Prisma.UserCreateInput {
      const createData: Prisma.UserCreateInput = {
         email: data.email,
      };

      if (data.password !== undefined) createData.password = data.password;
      if (data.role !== undefined) createData.role = data.role;
      if (data.isBanned !== undefined) createData.isBanned = data.isBanned;
      if (data.isSuspended !== undefined) createData.isSuspended = data.isSuspended;
      if (data.isDeleted !== undefined) createData.isDeleted = data.isDeleted;

      if (data.termsAccepted !== undefined) createData.termsAccepted = data.termsAccepted;
      if (data.termsAcceptedAt !== undefined) createData.termsAcceptedAt = data.termsAcceptedAt;
      if (data.termsVersion !== undefined) createData.termsVersion = data.termsVersion;
      if (data.privacyAcknowledged !== undefined) createData.privacyAcknowledged = data.privacyAcknowledged;
      if (data.privacyAcknowledgedAt !== undefined) createData.privacyAcknowledgedAt = data.privacyAcknowledgedAt;
      if (data.privacyVersion !== undefined) createData.privacyVersion = data.privacyVersion;

      return createData;
   }

   /**
    * Builds user update query.
    *
    * @param data - User update data.
    * @returns Prisma user update input.
    */
   private buildUserUpdateInput(data: UpdateUserDto): Prisma.UserUpdateInput {
      const { name, selfieStatus } = data;

      const updateData: Prisma.UserUpdateInput = {};

      if (data.email !== undefined) updateData.email = data.email;

      if (data.password !== undefined) updateData.password = data.password;
      if (data.role !== undefined) updateData.role = data.role;
      if (data.isBanned !== undefined) updateData.isBanned = data.isBanned;
      if (data.bannedAt !== undefined) updateData.bannedAt = data.bannedAt;
      if (data.isSuspended !== undefined) updateData.isSuspended = data.isSuspended;
      if (data.suspendedAt !== undefined) updateData.suspendedAt = data.suspendedAt;
      if (data.isDeleted !== undefined) updateData.isDeleted = data.isDeleted;
      if (data.isVerified !== undefined) updateData.isVerified = data.isVerified;

      const profileUpdateData: Prisma.ProfileUpdateWithoutUserInput = {};
      const profileCreateData: Prisma.ProfileCreateWithoutUserInput = {};

      if (name !== undefined) {
         profileUpdateData.name = name;
         profileCreateData.name = name;
      }

      if (selfieStatus !== undefined) {
         profileUpdateData.selfieStatus = selfieStatus;
         profileCreateData.selfieStatus = selfieStatus;
      }

      if (Object.keys(profileUpdateData).length > 0) {
         updateData.profile = {
            upsert: {
               create: profileCreateData,
               update: profileUpdateData,
            },
         };
      }

      return updateData;
   }
}
