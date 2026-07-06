import { UserOnboardingStatusDto } from "@/dtos/auth.me.dto";
import { UserDto, toUserDto } from "@/dtos/user.dto";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ProfileStatus, User } from "@prisma/client";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";

export class UserService implements IUserService {
   constructor(private userRepository: IUserRepository) {}

   async createUser(userData: CreateUserDto): Promise<UserDto> {
      if (userData.email && (await this.userRepository.findByEmail(userData.email))) {
         throw new ApiError(409, `User with email ${userData.email} already exists`);
      }
      if (userData.mobileNumber && (await this.userRepository.findByMobileNumber(userData.mobileNumber))) {
         throw new ApiError(409, `User with mobile number ${userData.mobileNumber} already exists`);
      }
      return toUserDto(await this.userRepository.create(userData));
   }

   async findOrCreateUser(email: string): Promise<UserDto> {
      const existingUser = await this.userRepository.findByEmail(email);
      if (existingUser) {
         return toUserDto(existingUser);
      }
      const newUser = await this.userRepository.create({ email });
      return toUserDto(newUser);
   }

   async findUserByEmail(email: string): Promise<UserDto | null> {
      const user = await this.userRepository.findByEmail(email);
      return user ? toUserDto(user) : null;
   }

   async getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<{ data: UserDto[]; total: number }> {
      const skip = page && limit ? (page - 1) * limit : undefined;
      const take = limit ? limit : undefined;

      const { users, total } = await this.userRepository.findAll({ searchQuery, selfieStatus }, skip, take);
      return { data: users.map((u: User) => toUserDto(u)), total };
   }

   async getUserById(userId: number): Promise<UserDto> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      return toUserDto(user);
   }

   async getOnboardingStatus(userId: number): Promise<UserOnboardingStatusDto> {
      const user = await this.userRepository.findOnboardingStatusById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      return {
         id: user.id,
         hasCompletedBasicDetails: user.profile?.hasCompletedBasicDetails || false,
         hasCompletedPartnerPreference: user.profile?.hasCompletedPartnerPreference || false,
         profileStatus: user.profile?.profileStatus || ProfileStatus.INCOMPLETE,
         hasCompletedImageUpload: user.profile?.hasCompletedImageUpload || false,
         selfieStatus: user.profile?.selfieStatus || null,
      };
   }

   async updateUser(userId: number, updateData: UpdateUserDto): Promise<UserDto> {
      console.log(`👉 updateData : `, updateData);
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }

      if (updateData.email) {
         const existingUser = await this.userRepository.findByEmail(updateData.email as string);
         if (existingUser && existingUser.id !== userId) {
            throw new ApiError(409, "Email is already in use by another account");
         }
      }

      const updatedUser = await this.userRepository.update(userId, updateData);
      return toUserDto(updatedUser);
   }

   async toggleBlockUser(userId: number): Promise<UserDto> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      const updatedUser = await this.userRepository.update(userId, { isBlocked: !user.isBlocked });
      return toUserDto(updatedUser);
   }

   async deleteUser(userId: number): Promise<void> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted) {
         throw new ApiError(404, "User not found");
      }
      await this.userRepository.update(userId, { isDeleted: true });
   }

   async getUserSelfieData(userId: number): Promise<any> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted || !user.profile) {
         throw new ApiError(404, "User profile not found");
      }
      
      const profile = user.profile;
      const { S3Service } = await import("@/services/s3.service");
      const s3Service = new S3Service();
      
      const url = profile.selfieUrl ? await s3Service.getPresignedUrl(profile.selfieUrl, 3600) : null;
      const leftUrl = profile.leftSelfieUrl ? await s3Service.getPresignedUrl(profile.leftSelfieUrl, 3600) : null;
      const rightUrl = profile.rightSelfieUrl ? await s3Service.getPresignedUrl(profile.rightSelfieUrl, 3600) : null;

      if (!url && !leftUrl && !rightUrl) {
         throw new ApiError(404, "User has no uploaded selfies");
      }

      return { 
         url, 
         leftUrl, 
         rightUrl, 
         locationLat: profile.lastLocationLat, 
         locationLng: profile.lastLocationLng 
      };
   }

   async getUserImagesData(userId: number): Promise<any> {
      const user = await this.userRepository.findById(userId);
      if (!user || user.isDeleted || !user.profile) {
         throw new ApiError(404, "User profile not found");
      }
      
      const images = user.profile.images;
      if (!images || images.length === 0) {
         throw new ApiError(404, "User has no uploaded images");
      }

      const { S3Service } = await import("@/services/s3.service");
      const s3Service = new S3Service();

      const imagesWithUrls = await Promise.all(
         images.map(async (img) => ({
            ...img,
            url: await s3Service.getPresignedUrl(img.imageUrl, 3600)
         }))
      );

      return imagesWithUrls;
   }
}
