import { PartnerPreference, Profile, ProfileStatus, SelfieStatus, User, UserFeature, PrivacySettings, SubscriptionPlan, UserSubscription } from "@prisma/client";

import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";

export type ProfileImageDto = {
   id: number;
   imageUrl: string;
   isPrimary: boolean;
};

export type ProfileWithImages = Profile & {
   images: ProfileImageDto[];
};

export type UserWithProfile = User & {
   profile: ProfileWithImages | null;
   partnerPreference?: PartnerPreference | null;
   userFeature?: UserFeature | null;
   privacySettings?: PrivacySettings | null;
   subscriptions?: (UserSubscription & { plan?: Pick<SubscriptionPlan, "id" | "name" | "price"> | null })[];
};

export type UserListFilters = {
   searchQuery?: string;
   selfieStatus?: string;
};

export type PaginatedUsersResult = {
   users: UserWithProfile[];
   total: number;
};

export type UserOnboardingStatus = {
   id: number;
   isDeleted: boolean;
   profile: {
      profileStatus: ProfileStatus;
      hasCompletedBasicDetails: boolean;
      hasCompletedImageUpload: boolean;
      hasCompletedPartnerPreference: boolean;
      selfieStatus: SelfieStatus | null;
   } | null;
};

export type UserFeatureAccessStatus = Pick<User, "id" | "isFoundingMember" | "isBanned" | "isSuspended" | "isDeleted" | "isDeleteRequested" | "deleteRequestStatus">;

export interface IUserRepository {
   create(data: CreateUserDto): Promise<UserWithProfile>;
   findAll(filters?: UserListFilters, skip?: number, take?: number): Promise<PaginatedUsersResult>;
   findSuspendedUsers(): Promise<UserWithProfile[]>;
   findById(id: number): Promise<UserWithProfile | null>;
   findFeatureAccessStatusById(id: number): Promise<UserFeatureAccessStatus | null>;
   findOnboardingStatusById(id: number): Promise<UserOnboardingStatus | null>;
   findByEmail(email: string): Promise<UserWithProfile | null>;
   findByProviderId(provider: string, providerUserId: string): Promise<UserWithProfile | null>;
   upsertSocialAccount(userId: number, provider: string, providerUserId: string): Promise<void>;
   update(id: number, data: UpdateUserDto): Promise<UserWithProfile>;
   updateFoundingMemberStatus(id: number, isFoundingMember: boolean, foundingMemberSince: Date | null): Promise<UserWithProfile>;
   delete(id: number): Promise<User>;
   clearDeviceTokens(userId: number): Promise<void>;
}
