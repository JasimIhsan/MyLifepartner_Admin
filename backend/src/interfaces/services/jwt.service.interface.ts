import { UserJwtPayload } from "@/types/express";

export interface IJwtService {
   signAccess(payload: object, expiresIn?: string | number): string;
   signRefresh(payload: object, expiresIn?: string | number): string;
   verifyAccess(token: string): UserJwtPayload;
   verifyRefresh(token: string): UserJwtPayload;
}
