import prisma from "@/config/prisma";
import { ProfileStatusType, SelfieStatusType, UserOnboardingStatusDto } from "@/dtos/auth.me.dto";
import { toUserDto, UserDto, UserImageDataDto, UserSelfieDataDto } from "@/dtos/user.dto";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserRepository, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { S3Service } from "@/services/s3.service";
import { ApiError } from "@/utils/ApiError";
import { CACHE_KEYS } from "@/utils/constants";
import { Prisma, SubscriptionStatus } from "@prisma/client";
import crypto from "crypto";

type PaginatedUsersDto = {
   data: UserDto[];
   total: number;
};

const PRESIGNED_URL_EXPIRY_SECONDS = 60 * 60;
const MAX_ACCOUNT_DELETION_REASON_LENGTH = 500;
const ACTIVE_SUBSCRIPTION_STATUSES = [SubscriptionStatus.ACTIVE, SubscriptionStatus.CANCELLED_PENDING_EXPIRY, SubscriptionStatus.BILLING_ISSUE, SubscriptionStatus.GRACE_PERIOD];
const NO_ACTIVE_SUBSCRIPTION_FILTER = "NO_ACTIVE_SUBSCRIPTION";

type AccountDeletionTokenPayload = {
   userId: number;
   reason: string | null;
};

export class UserService implements IUserService {
   constructor(
      private readonly userRepository: IUserRepository,
      private readonly s3Service: S3Service,
      private readonly emailService: IEmailService,
      private readonly cacheService: ICacheService
   ) {}

   /**
    * Creates a user.
    *
    * @param userData - User creation data.
    * @returns Created user.
    */
   async createUser(userData: CreateUserDto): Promise<UserDto> {
      await this.ensureEmailIsAvailable(userData.email);
      await this.ensureMobileNumberIsAvailable(userData.mobileNumber);

      const user = await this.userRepository.create(userData);

      return toUserDto(user);
   }

   /**
    * Finds or creates a user by email.
    *
    * @param email - User email.
    * @returns Existing or created user.
    */
   async findOrCreateUser(email: string): Promise<UserDto> {
      const existingUser = await this.userRepository.findByEmail(email);

      if (existingUser) {
         return toUserDto(existingUser);
      }

      const newUser = await this.userRepository.create({
         email,
      });

      return toUserDto(newUser);
   }

   /**
    * Finds a user by email.
    *
    * @param email - User email.
    * @returns User, or null if not found.
    */
   async findUserByEmail(email: string): Promise<UserDto | null> {
      const user = await this.userRepository.findByEmail(email);

      return user ? toUserDto(user) : null;
   }

   /**
    * Gets users with filters and pagination.
    *
    * @param searchQuery - Optional search query.
    * @param page - Page number.
    * @param limit - Number of users to fetch.
    * @param selfieStatus - Optional selfie status filter.
    * @returns Users and total matching count.
    */
   async getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<PaginatedUsersDto> {
      const skip = page && limit ? (page - 1) * limit : undefined;
      const take = limit;

      const { users, total } = await this.userRepository.findAll(
         {
            searchQuery,
            selfieStatus,
         },
         skip,
         take
      );

      return {
         data: users.map(toUserDto),
         total,
      };
   }

   async getGracePeriodSubscriptionUsers(searchQuery?: string, page?: number, limit?: number): Promise<PaginatedUsersDto> {
      const skip = page && limit ? (page - 1) * limit : undefined;
      const take = limit;
      const trimmedSearch = searchQuery?.trim();

      const where: Prisma.UserWhereInput = {
         isDeleted: false,
         subscriptions: {
            some: {
               status: SubscriptionStatus.GRACE_PERIOD,
            },
         },
      };

      if (trimmedSearch) {
         where.OR = [
            {
               profile: {
                  name: {
                     contains: trimmedSearch,
                     mode: "insensitive",
                  },
               },
            },
            {
               email: {
                  contains: trimmedSearch,
                  mode: "insensitive",
               },
            },
            {
               mobileNumber: {
                  contains: trimmedSearch,
                  mode: "insensitive",
               },
            },
         ];
      }

      const [users, total] = await prisma.$transaction([
         prisma.user.findMany({
            where,
            include: {
               profile: {
                  include: {
                     images: true,
                     job: true,
                  },
               },
               partnerPreference: true,
               privacySettings: true,
               userFeature: true,
               subscriptions: {
                  where: {
                     status: SubscriptionStatus.GRACE_PERIOD,
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
            },
            orderBy: {
               updatedAt: "desc",
            },
            skip,
            take,
         }),
         prisma.user.count({ where }),
      ]);

      return {
         data: users.map(toUserDto),
         total,
      };
   }

   async getSubscriptionUsers(query: { search?: string; page?: number; limit?: number; status?: string; planId?: number }): Promise<PaginatedUsersDto> {
      const skip = query.page && query.limit ? (query.page - 1) * query.limit : undefined;
      const take = query.limit;
      const trimmedSearch = query.search?.trim();
      const status = query.status?.trim();

      const activeSubscriptionFilter: Prisma.UserSubscriptionWhereInput = {
         status: {
            in: ACTIVE_SUBSCRIPTION_STATUSES,
         },
      };

      if (status && status !== "ALL" && status !== NO_ACTIVE_SUBSCRIPTION_FILTER) {
         activeSubscriptionFilter.status = status as SubscriptionStatus;
      }

      if (query.planId) {
         activeSubscriptionFilter.planId = query.planId;
      }

      const shouldFilterByActiveSubscription = Boolean((status && status !== "ALL" && status !== NO_ACTIVE_SUBSCRIPTION_FILTER) || query.planId);

      const where: Prisma.UserWhereInput = {
         isDeleted: false,
      };

      if (status === NO_ACTIVE_SUBSCRIPTION_FILTER) {
         where.subscriptions = {
            none: {
               status: {
                  in: ACTIVE_SUBSCRIPTION_STATUSES,
               },
            },
         };
      } else if (shouldFilterByActiveSubscription) {
         where.subscriptions = {
            some: activeSubscriptionFilter,
         };
      }

      if (trimmedSearch) {
         where.OR = [
            {
               profile: {
                  name: {
                     contains: trimmedSearch,
                     mode: "insensitive",
                  },
               },
            },
            {
               email: {
                  contains: trimmedSearch,
                  mode: "insensitive",
               },
            },
            {
               mobileNumber: {
                  contains: trimmedSearch,
                  mode: "insensitive",
               },
            },
         ];
      }

      const [users, total] = await prisma.$transaction([
         prisma.user.findMany({
            where,
            include: {
               profile: {
                  include: {
                     images: true,
                     job: true,
                  },
               },
               partnerPreference: true,
               privacySettings: true,
               userFeature: true,
               subscriptions: {
                  where: {
                     status: {
                        in: ACTIVE_SUBSCRIPTION_STATUSES,
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
            },
            orderBy: {
               updatedAt: "desc",
            },
            skip,
            take,
         }),
         prisma.user.count({ where }),
      ]);

      return {
         data: users.map(toUserDto),
         total,
      };
   }

   /**
    * Gets a user by ID.
    *
    * @param userId - User ID.
    * @returns User.
    */
   async getUserById(userId: number): Promise<UserDto> {
      const user = await this.findActiveUserById(userId);

      const dto = toUserDto(user);
      const primaryImage = user.profile?.images?.find((img) => img.isPrimary) ?? user.profile?.images?.[0] ?? null;
      if (primaryImage) {
         const presignedImageUrl = await this.getPresignedUrlOrNull(primaryImage.imageUrl);
         dto.primaryImageId = primaryImage.id;
         dto.primaryImage = {
            imageId: primaryImage.id,
            presignedImageUrl,
         };
         dto.primaryImageUrl = presignedImageUrl;
      }

      return dto;
   }

   /**
    * Gets complete user details for admin.
    *
    * @param userId - User ID.
    * @returns Complete user data including relations.
    */
   async getCompleteUserDetailsForAdmin(userId: number): Promise<any> {
      const user = await prisma.user.findUnique({
         where: { id: userId },
         include: {
            profile: {
               include: {
                  images: true,
                  job: true,
               },
            },
            partnerPreference: true,
            privacySettings: true,
            userFeature: true,
            subscriptions: {
               include: {
                  plan: {
                     select: {
                        id: true,
                        name: true,
                        price: true,
                        durationDays: true,
                     },
                  },
               },
               orderBy: {
                  createdAt: "desc",
               },
            },
            archivedData: true,
            deviceTokens: true,
         },
      });

      if (!user) {
         throw new ApiError(404, "User not found");
      }

      // Hide sensitive data
      const { password, ...safeUser } = user;

      // Map image URLs if necessary
      if (safeUser.profile?.images) {
         safeUser.profile.images = await Promise.all(
            safeUser.profile.images.map(async (img) => {
               const presignedImageUrl = (await this.getPresignedUrlOrNull(img.imageUrl)) || img.imageUrl;
               return {
                  ...img,
                  imageId: img.id,
                  imageUrl: presignedImageUrl,
                  presignedImageUrl,
               };
            })
         );
      }
      if (safeUser.profile?.selfieUrl) {
         safeUser.profile.selfieUrl = await this.getPresignedUrlOrNull(safeUser.profile.selfieUrl) || safeUser.profile.selfieUrl;
      }
      if (safeUser.profile?.leftSelfieUrl) {
         safeUser.profile.leftSelfieUrl = await this.getPresignedUrlOrNull(safeUser.profile.leftSelfieUrl) || safeUser.profile.leftSelfieUrl;
      }
      if (safeUser.profile?.rightSelfieUrl) {
         safeUser.profile.rightSelfieUrl = await this.getPresignedUrlOrNull(safeUser.profile.rightSelfieUrl) || safeUser.profile.rightSelfieUrl;
      }

      return safeUser;
   }

   /**
    * Gets user onboarding status.
    *
    * @param userId - User ID.
    * @returns User onboarding status.
    */
   async getOnboardingStatus(userId: number): Promise<UserOnboardingStatusDto> {
      const user = await this.userRepository.findOnboardingStatusById(userId);

      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      const profile = user.profile;
      const hasCompletedBasicDetails = profile?.hasCompletedBasicDetails ?? false;
      const hasCompletedPartnerPreference = profile?.hasCompletedPartnerPreference ?? false;
      const hasCompletedImageUpload = profile?.hasCompletedImageUpload ?? false;
      const selfieStatus = (profile?.selfieStatus as SelfieStatusType) ?? null;
      const hasFinishedOnboarding = hasCompletedBasicDetails && hasCompletedPartnerPreference && hasCompletedImageUpload && selfieStatus !== null;
      const profileStatus: ProfileStatusType = hasFinishedOnboarding ? "COMPLETED" : ((profile?.profileStatus as ProfileStatusType) ?? "INCOMPLETE");

      return {
         id: user.id,
         hasCompletedBasicDetails,
         hasCompletedPartnerPreference,
         profileStatus,
         hasCompletedImageUpload,
         selfieStatus,
      };
   }

   /**
    * Updates a user.
    *
    * @param userId - User ID.
    * @param updateData - User update data.
    * @returns Updated user.
    */
   async updateUser(userId: number, updateData: UpdateUserDto): Promise<UserDto> {
      await this.findActiveUserById(userId);

      if (updateData.email) {
         await this.ensureEmailIsAvailable(updateData.email, userId);
      }

      if (updateData.mobileNumber) {
         await this.ensureMobileNumberIsAvailable(updateData.mobileNumber, userId);
      }

      const updatedUser = await this.userRepository.update(userId, updateData);

      return toUserDto(updatedUser);
   }

   async toggleFoundingMemberStatus(userId: number): Promise<{ user: UserDto; previousIsFoundingMember: boolean; previousFoundingMemberSince: Date | null }> {
      const user = await this.findActiveUserById(userId);
      const previousIsFoundingMember = user.isFoundingMember;
      const previousFoundingMemberSince = user.foundingMemberSince;
      const isFoundingMember = !previousIsFoundingMember;

      if (isFoundingMember && !user.isVerified) {
         throw new ApiError(403, "Only verified users can be granted founding-member status");
      }

      const foundingMemberSince = isFoundingMember
         ? (user.foundingMemberSince ?? new Date())
         : null;

      const updatedUser = await this.userRepository.updateFoundingMemberStatus(userId, isFoundingMember, foundingMemberSince);

      return {
         user: toUserDto(updatedUser),
         previousIsFoundingMember,
         previousFoundingMemberSince,
      };
   }

   async toggleBanStatus(id: number): Promise<UserDto> {
      const user = await this.userRepository.findById(id);

      if (!user) {
         throw new ApiError(404, "User not found");
      }

      const updatedUser = await this.userRepository.update(id, {
         isBanned: !user.isBanned,
         bannedAt: !user.isBanned ? new Date() : null,
      });

      return toUserDto(updatedUser);
   }

   /**
    * Lifts user suspension.
    */
   async liftSuspension(id: number): Promise<UserDto> {
      const user = await this.userRepository.findById(id);

      if (!user) {
         throw new ApiError(404, "User not found");
      }

      const updatedUser = await this.userRepository.update(id, {
         isSuspended: false,
         suspendedAt: null,
      });

      return toUserDto(updatedUser);
   }

   /**
    * Gets all suspended users.
    */
   async getSuspendedUsers(): Promise<UserDto[]> {
      const users = await this.userRepository.findSuspendedUsers();
      return users.map(toUserDto);
   }

   /**
    * Soft deletes a user.
    *
    * @param userId - User ID.
    * @returns Nothing.
    */
   async deleteUser(userId: number): Promise<void> {
      await this.findActiveUserById(userId);

      await this.userRepository.update(userId, {
         isDeleted: true,
      });
   }

   /**
    * Gets user selfie data.
    *
    * @param userId - User ID.
    * @returns User selfie data.
    */
   async getUserSelfieData(userId: number): Promise<UserSelfieDataDto> {
      const user = await this.findActiveUserWithProfile(userId);
      const profile = user.profile;

      const [url, leftUrl, rightUrl] = await Promise.all([this.getPresignedUrlOrNull(profile.selfieUrl), this.getPresignedUrlOrNull(profile.leftSelfieUrl), this.getPresignedUrlOrNull(profile.rightSelfieUrl)]);

      if (!url && !leftUrl && !rightUrl) {
         throw new ApiError(404, "User has no uploaded selfies");
      }

      return {
         url,
         leftUrl,
         rightUrl,
         locationLat: profile.lastLocationLat,
         locationLng: profile.lastLocationLng,
      };
   }

   /**
    * Gets user image data.
    *
    * @param userId - User ID.
    * @returns User images with signed URLs.
    */
   async getUserImagesData(userId: number): Promise<UserImageDataDto[]> {
      const user = await this.findActiveUserWithProfile(userId);
      const images = user.profile.images;

      if (images.length === 0) {
         throw new ApiError(404, "User has no uploaded images");
      }

      return Promise.all(
         images.map(async (image) => {
            const presignedImageUrl = await this.s3Service.getPresignedUrl(image.imageUrl, PRESIGNED_URL_EXPIRY_SECONDS);
            return {
               ...image,
               imageId: image.id,
               imageUrl: presignedImageUrl,
               presignedImageUrl,
               url: presignedImageUrl,
            };
         })
      );
   }

   /**
    * Validates user account status.
    *
    * @param userId - User ID.
    */
   async validateUserAccountStatus(userId: number): Promise<void> {
      const user = await this.userRepository.findById(userId);

      if (!user) {
         throw new ApiError(401, "User not found");
      }

      if (user.isBanned) {
         throw new ApiError(403, "Your account has been permanently banned.");
      }

      if (user.isDeleted) {
         throw new ApiError(403, "Your account has been deleted.");
      }

      if (user.isDeleteRequested && user.deleteRequestStatus === "PENDING") {
         throw new ApiError(403, "Your account deletion is pending approval.");
      }

      if (user.isSuspended) {
         throw new ApiError(403, "Your account is temporarily suspended.");
      }
   }

   /**
    * Finds an active user by ID.
    *
    * @param userId - User ID.
    * @returns Active user.
    */
   private async findActiveUserById(userId: number) {
      const user = await this.userRepository.findById(userId);

      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      return user;
   }

   private parseAccountDeletionTokenPayload(value: string): AccountDeletionTokenPayload {
      try {
         const parsed = JSON.parse(value) as Partial<AccountDeletionTokenPayload>;
         const userId = Number(parsed.userId);

         if (Number.isInteger(userId) && userId > 0) {
            const reason = typeof parsed.reason === "string" ? parsed.reason.trim() : "";
            return { userId, reason: reason || null };
         }
      } catch {
         // Existing links cached only the user id; keep them valid until expiry.
      }

      const userId = Number(value);
      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(400, "Invalid or expired verification token");
      }

      return { userId, reason: null };
   }

   /**
    * Finds an active user with profile.
    *
    * @param userId - User ID.
    * @returns Active user with profile.
    */
   private async findActiveUserWithProfile(userId: number): Promise<UserWithProfile & { profile: NonNullable<UserWithProfile["profile"]> }> {
      const user = await this.findActiveUserById(userId);

      if (!user.profile) {
         throw new ApiError(404, "User profile not found");
      }

      return user as UserWithProfile & { profile: NonNullable<UserWithProfile["profile"]> };
   }

   /**
    * Checks whether email is available.
    *
    * @param email - User email.
    * @param ignoreUserId - Optional user ID to ignore.
    * @returns Nothing.
    */
   private async ensureEmailIsAvailable(email?: string | null, ignoreUserId?: number): Promise<void> {
      if (!email) {
         return;
      }

      const existingUser = await this.userRepository.findByEmail(email);

      if (existingUser && existingUser.id !== ignoreUserId) {
         throw new ApiError(409, "Email is already in use by another account");
      }
   }

   /**
    * Checks whether mobile number is available.
    *
    * @param mobileNumber - User mobile number.
    * @param ignoreUserId - Optional user ID to ignore.
    * @returns Nothing.
    */
   private async ensureMobileNumberIsAvailable(mobileNumber?: string | null, ignoreUserId?: number): Promise<void> {
      if (!mobileNumber) {
         return;
      }

      const existingUser = await this.userRepository.findByMobileNumber(mobileNumber);

      if (existingUser && existingUser.id !== ignoreUserId) {
         throw new ApiError(409, "Mobile number is already in use by another account");
      }
   }

   /**
    * Gets presigned URL if image key exists.
    *
    * @param imageKey - Image key.
    * @returns Presigned URL, or null.
    */
   private async getPresignedUrlOrNull(imageKey?: string | null): Promise<string | null> {
      if (!imageKey) {
         return null;
      }

      return this.s3Service.getPresignedUrl(imageKey, PRESIGNED_URL_EXPIRY_SECONDS);
   }

   /**
    * Requests account deletion by sending a verification email.
    */
   async requestAccountDeletion(userId: number, reason: string): Promise<void> {
      const trimmedReason = reason.trim();
      if (!trimmedReason) {
         throw new ApiError(400, "Account deletion reason is required");
      }

      if (trimmedReason.length > MAX_ACCOUNT_DELETION_REASON_LENGTH) {
         throw new ApiError(400, `Account deletion reason must be ${MAX_ACCOUNT_DELETION_REASON_LENGTH} characters or fewer`);
      }

      const user = await this.findActiveUserById(userId);
      if (!user.email) {
         throw new ApiError(400, "User email not found");
      }

      if (user.isDeleteRequested && user.deleteRequestStatus === "PENDING") {
         throw new ApiError(400, "Account deletion is already requested and pending approval");
      }

      const token = crypto.randomBytes(32).toString("hex");
      const cacheKey = CACHE_KEYS.ACCOUNT_DELETION_TOKEN(token);

      // Token valid for 1 hour (3600 seconds)
      await this.cacheService.setCache(
         cacheKey,
         JSON.stringify({
            userId,
            reason: trimmedReason,
         }),
         3600
      );
      await this.emailService.sendAccountDeletionEmail(user.email, token);
   }

   /**
    * Verifies account deletion token, marks request as pending, and clears session.
    */
   async verifyAccountDeletion(token: string): Promise<number> {
      const cacheKey = CACHE_KEYS.ACCOUNT_DELETION_TOKEN(token);
      const tokenValue = await this.cacheService.getCache(cacheKey);

      if (!tokenValue) {
         throw new ApiError(400, "Invalid or expired verification token");
      }

      const { userId, reason } = this.parseAccountDeletionTokenPayload(tokenValue);
      const user = await this.userRepository.findById(userId);

      if (!user) {
         throw new ApiError(404, "User not found");
      }

      await prisma.user.update({
         where: { id: userId },
         data: {
            isDeleteRequested: true,
            deleteRequestedAt: new Date(),
            deleteRequestStatus: "PENDING",
            deleteRequestReason: reason,
         },
      });

      // Token used, remove from cache
      await this.cacheService.deleteCache(cacheKey);

      // Clear sessions from all devices
      await this.userRepository.clearDeviceTokens(userId);

      return userId;
   }

   /**
    * Gets all pending deletion requests.
    */
   async getPendingDeletionRequests(page?: number, limit?: number): Promise<{ data: UserDto[]; total: number }> {
      const skip = page && limit ? (page - 1) * limit : undefined;
      const take = limit;

      const [users, total] = await prisma.$transaction([
         prisma.user.findMany({
            where: { deleteRequestStatus: "PENDING" },
            include: {
               profile: { include: { images: true } },
               partnerPreference: true,
               userFeature: true,
               privacySettings: true,
            },
            orderBy: { deleteRequestedAt: "desc" },
            skip,
            take,
         }),
         prisma.user.count({ where: { deleteRequestStatus: "PENDING" } }),
      ]);

      return {
         data: users.map(toUserDto),
         total,
      };
   }

   /**
    * Rejects a deletion request.
    */
   async rejectDeletionRequest(userId: number, adminId: number): Promise<void> {
      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user || user.deleteRequestStatus !== "PENDING") {
         throw new ApiError(400, "Invalid or already processed deletion request");
      }

      await prisma.user.update({
         where: { id: userId },
         data: {
            deleteRequestStatus: "REJECTED",
            deleteRequestReason: null,
         },
      });
   }

   /**
    * Fetches paginated archived (deleted) users.
    */
   async getArchivedUsers(page: number = 1, limit: number = 10): Promise<{ data: any[]; total: number }> {
      const skip = (page - 1) * limit;

      const [data, total] = await Promise.all([
         prisma.archivedUserData.findMany({
            skip,
            take: limit,
            orderBy: { archivedAt: "desc" },
         }),
         prisma.archivedUserData.count(),
      ]);

      return { data, total };
   }

   /**
    * Approves a deletion request, archives data, and scrubs PII.
    */
   async approveDeletionRequest(userId: number, adminId: number): Promise<void> {
      const user = await prisma.user.findUnique({
         where: { id: userId },
         include: { profile: { include: { images: true } }, privacySettings: true },
      });

      if (!user || user.deleteRequestStatus !== "PENDING") {
         throw new ApiError(400, "Invalid or already processed deletion request");
      }

      // We are retaining original data instead of hashing it for Admin viewing.

      // Anonymize user
      const anonymizedEmail = `deleted_${userId}_${crypto.randomUUID()}@premiumglobalcorp.com`;

      await prisma.$transaction(async (tx) => {
         // 1. Create archive
         await tx.archivedUserData.create({
            data: {
               userId,
               originalEmail: user.email,
               originalPhone: user.mobileNumber,
               originalName: user.profile?.name,
               reasonForArchive: user.deleteRequestReason || `Admin ${adminId} approved account deletion`,
            },
         });

         // 2. Anonymize user
         await tx.user.update({
            where: { id: userId },
            data: {
               email: anonymizedEmail,
               mobileNumber: null,
               password: null,
               isDeleted: true,
               deleteRequestStatus: "APPROVED",
            },
         });

         // 3. Anonymize profile
         if (user.profile) {
            await tx.profile.update({
               where: { userId },
               data: {
                  name: "Deleted User",
                  dateOfBirth: null,
                  city: null,
                  state: null,
                  country: null,
                  highestEducation: null,
                  bio: null,
                  selfieUrl: null,
                  leftSelfieUrl: null,
                  rightSelfieUrl: null,
                  lastLocationLat: null,
                  lastLocationLng: null,
               },
            });

            // Delete User Images
            if (user.profile.images.length > 0) {
               await tx.userImage.deleteMany({
                  where: { profileId: user.profile.id },
               });
            }
         }

         // 4. Clear privacy image
         if (user.privacySettings?.blurredImageUrl) {
            await tx.privacySettings.update({
               where: { userId },
               data: { blurredImageUrl: null },
            });
         }

         // 5. Delete device tokens and social accounts
         await tx.deviceToken.deleteMany({ where: { userId } });
         await tx.socialAccount.deleteMany({ where: { userId } });
      });

      // Cleanup files from S3 asynchronously
      const filesToDelete = [];
      if (user.profile?.selfieUrl) filesToDelete.push(user.profile.selfieUrl);
      if (user.profile?.leftSelfieUrl) filesToDelete.push(user.profile.leftSelfieUrl);
      if (user.profile?.rightSelfieUrl) filesToDelete.push(user.profile.rightSelfieUrl);
      if (user.privacySettings?.blurredImageUrl) filesToDelete.push(user.privacySettings.blurredImageUrl);
      user.profile?.images.forEach((img) => filesToDelete.push(img.imageUrl));

      if (filesToDelete.length > 0) {
         filesToDelete.forEach((file) => {
            this.s3Service.deleteFromS3(file).catch((err: unknown) => {
               console.error(`Failed to delete file ${file} from S3 during account deletion`, err);
            });
         });
      }
   }
}
