import { UserDto } from "@/dtos/user.dto";
import { UserOnboardingStatusDto } from "@/dtos/auth.me.dto";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";

export interface IUserService {
   createUser(userData: CreateUserDto): Promise<UserDto>;
   findOrCreateUser(email: string): Promise<UserDto>;
   findUserByEmail(email: string): Promise<UserDto | null>;
   getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<{ data: UserDto[]; total: number }>;
   getUserById(userId: number): Promise<UserDto>;
   getOnboardingStatus(userId: number): Promise<UserOnboardingStatusDto>;
   updateUser(userId: number, updateData: UpdateUserDto): Promise<UserDto>;
   toggleBlockUser(userId: number): Promise<UserDto>;
   deleteUser(userId: number): Promise<void>;
   getUserSelfieData(userId: number): Promise<any>;
   getUserImagesData(userId: number): Promise<any>;
}
