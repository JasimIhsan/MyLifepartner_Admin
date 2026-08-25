import { PartnerPreference, Profile, ProfileStatus, SelfieStatus, User, Job, PrivacySettings, SubscriptionPlan, UserSubscription } from "@prisma/client";
import { PresignedProfileImageDto } from "@/dtos/image.dto";

const ACTIVE_SUBSCRIPTION_STATUSES = new Set(["ACTIVE", "CANCELLED_PENDING_EXPIRY", "BILLING_ISSUE", "GRACE_PERIOD"]);

export type UserSubscriptionSummaryDto = {
   id: number;
   planId: number;
   status: string;
   startDate: Date;
   endDate: Date;
   gracePeriodEndsAt: Date | null;
   willRenew: boolean;
   plan: {
      id: number;
      name: string;
      price: number;
   } | null;
};

export interface UserDto {
   id: number;

   name: string | null;
   email: string | null;
   role: string;
   isVerified: boolean;
   isBanned: boolean;
   isSuspended: boolean;
   isFoundingMember: boolean;
   foundingMemberSince: Date | null;
   bannedAt: Date | null;
   suspendedAt: Date | null;
   isDeleted: boolean;
   isDeleteRequested: boolean;
   deleteRequestedAt: Date | null;
   deleteRequestStatus: string | null;
   deleteRequestReason: string | null;
   profileStatus: ProfileStatus;
   hasCompletedBasicDetails: boolean;
   hasCompletedImageUpload: boolean;
   hasCompletedPartnerPreference: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   primaryImageId?: number | null;
   primaryImage?: PresignedProfileImageDto | null;
   primaryImageUrl?: string | null;
   privacyEnabled?: boolean;
   activeSubscription?: UserSubscriptionSummaryDto | null;

   // Profile demographics
   gender?: string | null;
   dateOfBirth?: Date | null;
   maritalStatus?: string | null;
   motherTongue?: string | null;
   city?: string | null;
   state?: string | null;
   country?: string | null;
   highestEducation?: string | null;
   occupation?: string | null;
   bio?: string | null;
   childrenStatus?: string | null;
   lookingFor?: string | null;
   smokingHabit?: string | null;
   drinkingHabit?: string | null;
   languages?: string[];
   profileCompletion?: number | null;

   createdAt: Date;
   updatedAt: Date;

   termsAccepted?: boolean;
   termsAcceptedAt?: Date | null;
   termsVersion?: string | null;
   privacyAcknowledged?: boolean;
   privacyAcknowledgedAt?: Date | null;
   privacyVersion?: string | null;
}

export const toUserDto = (
   user: User & {
      profile?: (Profile & { job?: Job | null; images?: { isPrimary: boolean; imageUrl: string }[] }) | null;
      partnerPreference?: PartnerPreference | null;
      privacySettings?: PrivacySettings | null;
      subscriptions?: (UserSubscription & { plan?: Pick<SubscriptionPlan, "id" | "name" | "price"> | null })[];
   }
): UserDto => {
   const activeSubscription = user.subscriptions?.find((subscription) => ACTIVE_SUBSCRIPTION_STATUSES.has(subscription.status)) ?? null;

   return {
      id: user.id,

      name: user.profile?.name || null,
      email: user.email,
      role: user.role,
      isVerified: user.isVerified,
      isBanned: user.isBanned,
      isSuspended: user.isSuspended,
      isFoundingMember: user.isFoundingMember,
      foundingMemberSince: user.foundingMemberSince,
      bannedAt: user.bannedAt,
      suspendedAt: user.suspendedAt,
      isDeleted: user.isDeleted,
      isDeleteRequested: user.isDeleteRequested,
      deleteRequestedAt: user.deleteRequestedAt,
      deleteRequestStatus: user.deleteRequestStatus,
      deleteRequestReason: user.deleteRequestReason,
      profileStatus: user.profile?.profileStatus || ProfileStatus.INCOMPLETE,
      hasCompletedBasicDetails: user.profile?.hasCompletedBasicDetails || false,
      hasCompletedImageUpload: user.profile?.hasCompletedImageUpload || false,
      hasCompletedPartnerPreference: user.profile?.hasCompletedPartnerPreference || false,
      selfieStatus: user.profile?.selfieStatus || null,
      selfieUrl: user.profile?.selfieUrl || null,
      primaryImageUrl: user.profile?.images?.find((img) => img.isPrimary)?.imageUrl || null,
      privacyEnabled: user.privacySettings?.privacyEnabled ?? false,
      activeSubscription: activeSubscription
         ? {
              id: activeSubscription.id,
              planId: activeSubscription.planId,
              status: activeSubscription.status,
              startDate: activeSubscription.startDate,
              endDate: activeSubscription.endDate,
              gracePeriodEndsAt: activeSubscription.gracePeriodEndsAt,
              willRenew: activeSubscription.willRenew,
              plan: activeSubscription.plan
                 ? {
                      id: activeSubscription.plan.id,
                      name: activeSubscription.plan.name,
                      price: activeSubscription.plan.price,
                   }
                 : null,
           }
         : null,

      gender: user.profile?.gender || null,
      dateOfBirth: user.profile?.dateOfBirth || null,
      maritalStatus: user.profile?.maritalStatus || null,
      motherTongue: user.profile?.motherTongue || null,
      city: user.profile?.city || null,
      state: user.profile?.state || null,
      country: user.profile?.country || null,
      highestEducation: user.profile?.highestEducation || null,
      occupation: user.profile?.job?.name || null,
      bio: user.profile?.bio || null,
      childrenStatus: user.profile?.childrenStatus || null,
      lookingFor: user.profile?.lookingFor || null,
      smokingHabit: user.profile?.smokingHabit || null,
      drinkingHabit: user.profile?.drinkingHabit || null,
      languages: user.profile?.languages || [],
      profileCompletion: user.profile?.profileCompletion || null,

      createdAt: user.createdAt,
      updatedAt: user.updatedAt,

      termsAccepted: user.termsAccepted,
      termsAcceptedAt: user.termsAcceptedAt,
      termsVersion: user.termsVersion,
      privacyAcknowledged: user.privacyAcknowledged,
      privacyAcknowledgedAt: user.privacyAcknowledgedAt,
      privacyVersion: user.privacyVersion,
   };
};

export type UserSelfieDataDto = {
   url: string | null;
   leftUrl: string | null;
   rightUrl: string | null;
   locationLat: number | null;
   locationLng: number | null;
};

export type UserImageDataDto = {
   id: number;
   imageId: number;
   imageUrl: string;
   presignedImageUrl: string;
   isPrimary: boolean;
   url: string;
};
