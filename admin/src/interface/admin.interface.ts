export interface AdminInterface {
   id: number;
   username: string;
   role: "ADMIN" | "SUPER_ADMIN";
   createdAt: string;
   updatedAt: string;
}
