import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import bcrypt from "bcrypt";
import { IAdminRepository } from "../../interfaces/repositories/admin.repository.interface";
import { IAdminAuthService } from "../../interfaces/services/admin.auth.service.interface";

import { IJwtService } from "../../interfaces/services/jwt.service.interface";

export class AdminAuthService implements IAdminAuthService {
   constructor(
      private adminRepository: IAdminRepository,
      private jwtService: IJwtService
   ) {}

   async login(username: string, password: string) {
      if (!username || !password) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      const admin = await this.adminRepository.findByUsername(username);

      if (!admin) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid username or password");
      }

      const isPasswordValid = await bcrypt.compare(password, admin.password);
      if (!isPasswordValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid username or password");
      }

      const accessToken = this.jwtService.signAccess(
         { id: admin.id, username: admin.username, role: admin.role },
         "15m" // short-lived
      );

      const refreshToken = this.jwtService.signRefresh(
         { id: admin.id, username: admin.username },
         "7d" // long-lived
      );

      return {
         user: { id: admin.id, username: admin.username, role: admin.role },
         accessToken,
         refreshToken,
      };
   }

   async refreshTokens(refreshToken: string) {
      if (!refreshToken) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Refresh token is required");
      }

      try {
         const decoded = this.jwtService.verifyRefresh(refreshToken);

         const admin = await this.adminRepository.findById(decoded.id);

         if (!admin) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid admin");
         }

         const accessToken = this.jwtService.signAccess({ id: admin.id, username: admin.username, role: admin.role }, "15m");

         const newRefreshToken = this.jwtService.signRefresh({ id: admin.id, username: admin.username }, "7d");

         return { accessToken, refreshToken: newRefreshToken };
      } catch (error) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid or expired refresh token");
      }
   }

   async logout(adminId: number) {
      // Stateless JWT means we just clear the cookies on the frontend
      // Revocation could be handled by a blocklist in the future if necessary
      return true;
   }
}
