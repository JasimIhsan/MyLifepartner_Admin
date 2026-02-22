import { User } from "@prisma/client";

export interface UserDto {
   id: number;
   mobileNumber: string;
   isProfileCompleted: boolean;
   createdAt: Date;
   updatedAt: Date;
}

export const toUserDto = (user: User): UserDto => ({
   id: user.id,
   mobileNumber: user.mobileNumber,
   isProfileCompleted: user.isProfileCompleted,
   createdAt: user.createdAt,
   updatedAt: user.updatedAt,
});
