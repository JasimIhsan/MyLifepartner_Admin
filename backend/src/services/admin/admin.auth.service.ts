import { IAdminRepository } from "@/interfaces/repositories/admin.repository.interface";
import { IAdminAuthService } from "@/interfaces/services/admin.auth.service.interface";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { Role } from "@/interfaces/services/admin.management.service.interface";
import bcrypt from "bcrypt";

type AdminAuthUserDto = {
   id: number;
   username: string;
   password?: string;
   role: Role;
};

type AdminAuthResponseDto = {
   user: AdminAuthUserDto;
   accessToken: string;
   refreshToken: string;
};

type AdminTokenResponseDto = {
   accessToken: string;
   refreshToken: string;
};

const ADMIN_ACCESS_TOKEN_EXPIRY = "15m";
const ADMIN_REFRESH_TOKEN_EXPIRY = "7d";
const INVALID_LOGIN_MESSAGE = "Invalid username or password";

export class AdminAuthService implements IAdminAuthService {
   constructor(
      private readonly adminRepository: IAdminRepository,
      private readonly jwtService: IJwtService
   ) {}

   /**
    * Logs in an admin.
    *
    * @param username - Admin username.
    * @param password - Admin password.
    * @returns Admin user with auth tokens.
    */
   async login(username: string, password: string): Promise<AdminAuthResponseDto> {
      const normalizedUsername = this.normalizeUsername(username);

      if (!password) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      const admin = await this.adminRepository.findByUsername(normalizedUsername) as unknown as AdminAuthUserDto;

      if (!admin) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, INVALID_LOGIN_MESSAGE);
      }

      const isPasswordValid = await bcrypt.compare(password, admin.password!);

      if (!isPasswordValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, INVALID_LOGIN_MESSAGE);
      }

      const tokens = this.generateAdminTokens(admin.id, admin.username, admin.role);

      return {
         user: this.toAdminAuthUserDto(admin.id, admin.username, admin.role),
         ...tokens,
      };
   }

   /**
    * Refreshes admin auth tokens.
    *
    * @param refreshToken - Admin refresh token.
    * @returns New auth tokens.
    */
   async refreshTokens(refreshToken: string): Promise<AdminTokenResponseDto> {
      if (!refreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      try {
         const decoded = this.jwtService.verifyRefresh(refreshToken);
         const admin = await this.adminRepository.findById(decoded.id) as unknown as AdminAuthUserDto;

         if (!admin) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid admin");
         }

         return this.generateAdminTokens(admin.id, admin.username, admin.role);
      } catch {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired refresh token");
      }
   }

   /**
    * Logs out an admin.
    *
    * @param adminId - Admin ID.
    * @returns Logout status.
    */
   async logout(_adminId: number): Promise<boolean> {
      return true;
   }

   /**
    * Generates admin auth tokens.
    *
    * @param id - Admin ID.
    * @param username - Admin username.
    * @param role - Admin role.
    * @returns Admin auth tokens.
    */
   private generateAdminTokens(id: number, username: string, role: Role): AdminTokenResponseDto {
      const accessPayload = {
         id,
         username,
         role,
      };

      const refreshPayload = {
         id,
         username,
         role,
      };

      return {
         accessToken: this.jwtService.signAccess(accessPayload, ADMIN_ACCESS_TOKEN_EXPIRY),
         refreshToken: this.jwtService.signRefresh(refreshPayload, ADMIN_REFRESH_TOKEN_EXPIRY),
      };
   }

   /**
    * Maps admin auth user response.
    *
    * @param id - Admin ID.
    * @param username - Admin username.
    * @param role - Admin role.
    * @returns Admin auth user.
    */
   private toAdminAuthUserDto(id: number, username: string, role: Role): AdminAuthUserDto {
      return {
         id,
         username,
         role,
      };
   }

   /**
    * Normalizes username.
    *
    * @param username - Admin username.
    * @returns Normalized username.
    */
   private normalizeUsername(username: string): string {
      const normalizedUsername = username?.trim();

      if (!normalizedUsername) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      return normalizedUsername;
   }
}
