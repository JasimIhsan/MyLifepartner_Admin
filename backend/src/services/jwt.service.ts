import { env } from "@/config/env";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { UserJwtPayload } from "@/types/express";
import jwt from "jsonwebtoken";

export class JwtService implements IJwtService {
   signAccess(payload: object, expiresIn: string | number = "15m"): string {
      return jwt.sign(payload, env.JWT_SECRET, { expiresIn: expiresIn as any });
   }

   signRefresh(payload: object, expiresIn: string | number = "7d"): string {
      return jwt.sign(payload, env.JWT_REFRESH_SECRET, { expiresIn: expiresIn as any });
   }

   verifyAccess(token: string): UserJwtPayload {
      return jwt.verify(token, env.JWT_SECRET) as UserJwtPayload;
   }

   verifyRefresh(token: string): UserJwtPayload {
      return jwt.verify(token, env.JWT_REFRESH_SECRET) as UserJwtPayload;
   }
}
