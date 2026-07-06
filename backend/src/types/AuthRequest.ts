import { Request } from "express";
import { UserJwtPayload } from "./express";

export interface AuthRequest extends Request {
   user: UserJwtPayload;
}
