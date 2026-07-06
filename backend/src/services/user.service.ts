import { UserOnboardingStatusDto, ProfileStatusType, SelfieStatusType } from "@/dtos/auth.me.dto";
import { toUserDto, UserDto, UserSelfieDataDto, UserImageDataDto } from "@/dtos/user.dto";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserRepository, ProfileImageDto, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { S3Service } from "@/services/s3.service";
import { ApiError } from "@/utils/ApiError";

type PaginatedUsersDto = {
   data: UserDto[];
   total: number;
};



const PRESIGNED_URL_EXPIRY_SECONDS = 60 * 60;

export class UserService implements IUserService {
   constructor(
      private readonly userRepository: IUserRepository,
      private readonly s3Service: S3Service
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

   /**
    * Gets a user by ID.
    *
    * @param userId - User ID.
    * @returns User.
    */
   async getUserById(userId: number): Promise<UserDto> {
      const user = await this.findActiveUserById(userId);

      return toUserDto(user);
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

      return {
         id: user.id,
         hasCompletedBasicDetails: user.profile?.hasCompletedBasicDetails ?? false,
         hasCompletedPartnerPreference: user.profile?.hasCompletedPartnerPreference ?? false,
         profileStatus: (user.profile?.profileStatus as ProfileStatusType) ?? "INCOMPLETE",
         hasCompletedImageUpload: user.profile?.hasCompletedImageUpload ?? false,
         selfieStatus: (user.profile?.selfieStatus as SelfieStatusType) ?? null,
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

   /**
    * Toggles user block status.
    *
    * @param userId - User ID.
    * @returns Updated user.
    */
   async toggleBlockUser(userId: number): Promise<UserDto> {
      const user = await this.findActiveUserById(userId);

      const updatedUser = await this.userRepository.update(userId, {
         isBlocked: !user.isBlocked,
      });

      return toUserDto(updatedUser);
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
         images.map(async (image) => ({
            ...image,
            url: await this.s3Service.getPresignedUrl(image.imageUrl, PRESIGNED_URL_EXPIRY_SECONDS),
         }))
      );
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
}
