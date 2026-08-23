export interface UserInterface {
   id: number;

   name: string | null;
   email: string | null;
   isBanned: boolean;
   isSuspended: boolean;
   isFoundingMember: boolean;
   foundingMemberSince?: string | Date | null;
   isDeleted: boolean;
   isDeleteRequested?: boolean;
   deleteRequestedAt?: string | Date | null;
   deleteRequestStatus?: "PENDING" | "APPROVED" | "REJECTED" | null;
   deleteRequestReason?: string | null;
   profileStatus: "INCOMPLETE" | "ONBOARDING_COMPLETED" | "COMPLETED";
   hasCompletedImageUpload: boolean;
   selfieStatus: SelfieStatus | null;
   selfieUrl: string | null;
   leftSelfieUrl?: string | null;
   rightSelfieUrl?: string | null;
   lastLocationLat?: number | null;
   lastLocationLng?: number | null;
   primaryImageUrl?: string | null;
   activeSubscription?: UserSubscriptionSummary | null;

   // Profile demographics
   gender?: string | null;
   dateOfBirth?: Date | null;
   maritalStatus?: string | null;
   heightCm?: number | null;
   caste?: string | null;
   motherTongue?: string | null;
   city?: string | null;
   state?: string | null;
   country?: string | null;
   highestEducation?: string | null;
   occupation?: string | null;
   bio?: string | null;
   profileCompletion?: number | null;

   createdAt: Date;
   updatedAt: Date;
}

export type SelfieStatus = "PENDING" | "APPROVED" | "REJECTED";

export type SubscriptionStatus = "ACTIVE" | "INACTIVE" | "CANCELLED" | "CANCELLED_PENDING_EXPIRY" | "BILLING_ISSUE" | "GRACE_PERIOD" | "EXPIRED";

export interface UserSubscriptionSummary {
   id: number;
   planId: number;
   status: SubscriptionStatus;
   startDate: string | Date;
   endDate: string | Date;
   gracePeriodEndsAt?: string | Date | null;
   willRenew: boolean;
   plan?: {
      id: number;
      name: string;
      price: number;
   } | null;
   store?: string | null;
   environment?: string | null;
}


