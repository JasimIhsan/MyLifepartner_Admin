import { JwtPayload } from "jsonwebtoken";

export interface UserJwtPayload extends JwtPayload {
   id: number;
   role?: string;
   mobileNumber?: string;
   username?: string;
}

declare global {
   namespace Express {
      interface Request {
         user?: UserJwtPayload;
      }
   }
}
