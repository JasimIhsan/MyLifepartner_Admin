export interface CreateUserDto {
   email: string;
   mobileNumber?: string;
   password?: string;
   role?: "USER" | "ADMIN" | "SUPER_ADMIN";
   isBanned?: boolean;
   isSuspended?: boolean;
   isDeleted?: boolean;
}

export interface UpdateUserDto {
   email?: string;
   mobileNumber?: string;
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
