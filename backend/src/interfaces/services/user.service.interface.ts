import { UserDto } from "@/dtos/user.dto";
import { UserOnboardingStatusDto } from "@/dtos/auth.me.dto";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { UserSelfieDataDto, UserImageDataDto } from "@/dtos/user.dto";

export interface IUserService {
   createUser(userData: CreateUserDto): Promise<UserDto>;
   findOrCreateUser(email: string): Promise<UserDto>;
   findUserByEmail(email: string): Promise<UserDto | null>;
   getUsers(searchQuery?: string, page?: number, limit?: number, selfieStatus?: string): Promise<{ data: UserDto[]; total: number }>;
   getGracePeriodSubscriptionUsers(searchQuery?: string, page?: number, limit?: number): Promise<{ data: UserDto[]; total: number }>;
   getSubscriptionUsers(query: { search?: string; page?: number; limit?: number; status?: string; planId?: number }): Promise<{ data: UserDto[]; total: number }>;
   getUserById(userId: number): Promise<UserDto>;
   getCompleteUserDetailsForAdmin(userId: number): Promise<any>;
   getOnboardingStatus(userId: number): Promise<UserOnboardingStatusDto>;
   updateUser(userId: number, updateData: UpdateUserDto): Promise<UserDto>;
   toggleFoundingMemberStatus(userId: number): Promise<{ user: UserDto; previousIsFoundingMember: boolean; previousFoundingMemberSince: Date | null }>;
   toggleBanStatus(userId: number): Promise<UserDto>;
   getSuspendedUsers(): Promise<UserDto[]>;
   liftSuspension(userId: number): Promise<UserDto>;
   deleteUser(userId: number): Promise<void>;
   getUserSelfieData(userId: number): Promise<UserSelfieDataDto>;
   getUserImagesData(userId: number): Promise<UserImageDataDto[]>;
   validateUserAccountStatus(userId: number): Promise<void>;
   requestAccountDeletion(userId: number, reason: string): Promise<void>;
   verifyAccountDeletion(token: string): Promise<number>;
   getPendingDeletionRequests(page?: number, limit?: number): Promise<{ data: UserDto[]; total: number }>;
   approveDeletionRequest(userId: number, adminId: number): Promise<void>;
   rejectDeletionRequest(userId: number, adminId: number): Promise<void>;

}
