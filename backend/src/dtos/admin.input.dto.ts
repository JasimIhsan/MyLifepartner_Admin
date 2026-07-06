export interface UpdateAdminDto {
   email?: string;
   name?: string;
   password?: string;
   role?: "ADMIN" | "SUPER_ADMIN";
   isBlocked?: boolean;
}
