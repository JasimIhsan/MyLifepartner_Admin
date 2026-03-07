export interface CreateAdminDto {
   username: string;
   password?: string;
   role: "ADMIN" | "SUPER_ADMIN";
}

export interface UpdateAdminDto {
   username?: string;
   password?: string;
   role?: "ADMIN" | "SUPER_ADMIN";
}
