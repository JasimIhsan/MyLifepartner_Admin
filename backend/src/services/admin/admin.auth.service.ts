import prisma from "@/config/prisma";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import bcrypt from "bcrypt";
import jwt from "jsonwebtoken";

class AdminAuthService {
   async login(username: string, password: string) {
      if (!username || !password) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      const admin = await prisma.admin.findUnique({
         where: { username },
      });

      if (!admin) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid username or password");
      }

      const isPasswordValid = await bcrypt.compare(password, admin.password);
      if (!isPasswordValid) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid username or password");
      }

      const accessToken = jwt.sign(
         { id: admin.id, username: admin.username, role: admin.role },
         process.env.JWT_SECRET || "default_secret",
         { expiresIn: "15m" } // short-lived
      );

      const refreshToken = jwt.sign(
         { id: admin.id, username: admin.username },
         process.env.JWT_REFRESH_SECRET || "default_refresh_secret",
         { expiresIn: "7d" } // long-lived
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
         const decoded: any = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET || "default_refresh_secret");

         const admin = await prisma.admin.findUnique({
            where: { id: decoded.id },
         });

         if (!admin) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid admin");
         }

         const accessToken = jwt.sign({ id: admin.id, username: admin.username, role: admin.role }, process.env.JWT_SECRET || "default_secret", { expiresIn: "15m" });

         const newRefreshToken = jwt.sign({ id: admin.id, username: admin.username }, process.env.JWT_REFRESH_SECRET || "default_refresh_secret", { expiresIn: "7d" });

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

export default new AdminAuthService();
