export interface CreateUserDto {
   email: string;

   password?: string;
   role?: "USER" | "ADMIN" | "SUPER_ADMIN";
   isBanned?: boolean;
   isSuspended?: boolean;
   isDeleted?: boolean;

   termsAccepted?: boolean;
   termsAcceptedAt?: Date;
   termsVersion?: string;
   privacyAcknowledged?: boolean;
   privacyAcknowledgedAt?: Date;
   privacyVersion?: string;
}

export interface UpdateUserDto {
   email?: string;

   password?: string;
   role?: "USER" | "ADMIN" | "SUPER_ADMIN";
   isBanned?: boolean;
   bannedAt?: Date | null;
   isSuspended?: boolean;
   suspendedAt?: Date | null;
   isDeleted?: boolean;
   name?: string; // Sometimes used to update the associated profile
   isVerified?: boolean;
   selfieStatus?: "PENDING" | "APPROVED" | "REJECTED"; // Added for admin verification
}
