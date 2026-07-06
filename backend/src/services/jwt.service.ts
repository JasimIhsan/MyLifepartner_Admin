import env from "@/config/env";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { UserJwtPayload } from "@/types/express";
import jwt, { SignOptions } from "jsonwebtoken";

const ACCESS_TOKEN_EXPIRY: SignOptions["expiresIn"] = "15m";
const REFRESH_TOKEN_EXPIRY: SignOptions["expiresIn"] = "7d";

export class JwtService implements IJwtService {
   /**
    * Signs an access token.
    *
    * @param payload - JWT payload.
    * @param expiresIn - Access token expiry time.
    * @returns Signed access token.
    */
   signAccess(payload: object, expiresIn: SignOptions["expiresIn"] = ACCESS_TOKEN_EXPIRY): string {
      return jwt.sign(payload, env.JWT_SECRET, {
         expiresIn,
      });
   }

   /**
    * Signs a refresh token.
    *
    * @param payload - JWT payload.
    * @param expiresIn - Refresh token expiry time.
    * @returns Signed refresh token.
    */
   signRefresh(payload: object, expiresIn: SignOptions["expiresIn"] = REFRESH_TOKEN_EXPIRY): string {
      return jwt.sign(payload, env.JWT_REFRESH_SECRET, {
         expiresIn,
      });
   }

   /**
    * Verifies an access token.
    *
    * @param token - Access token.
    * @returns Decoded user JWT payload.
    */
   verifyAccess(token: string): UserJwtPayload {
      return jwt.verify(token, env.JWT_SECRET) as UserJwtPayload;
   }

   /**
    * Verifies a refresh token.
    *
    * @param token - Refresh token.
    * @returns Decoded user JWT payload.
    */
   verifyRefresh(token: string): UserJwtPayload {
      return jwt.verify(token, env.JWT_REFRESH_SECRET) as UserJwtPayload;
   }
}
