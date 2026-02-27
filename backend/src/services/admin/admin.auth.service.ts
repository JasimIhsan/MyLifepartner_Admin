import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import jwt from "jsonwebtoken";

class AdminAuthService {
   async login(username: string, password: string): Promise<{ user: { username: string; role: string }; accessToken: string; refreshToken: string }> {
      console.log("username: ", username);
      console.log("password: ", password);
      if (!username || !password) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Username and password are required");
      }

      const DEFAULT_USERNAME = "admin";
      const DEFAULT_PASSWORD = "asdfasdf";

      if (username !== DEFAULT_USERNAME || password !== DEFAULT_PASSWORD) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid username or password");
      }

      const accessToken = jwt.sign({ id: 1, username: DEFAULT_USERNAME }, process.env.JWT_SECRET || "default_secret", { expiresIn: "1d" });
      const refreshToken = jwt.sign({ id: 1, username: DEFAULT_USERNAME }, process.env.JWT_SECRET || "default_secret", { expiresIn: "7d" });

      return { user: { username: DEFAULT_USERNAME, role: "ADMIN" }, accessToken, refreshToken };
   }
}

export default new AdminAuthService();
