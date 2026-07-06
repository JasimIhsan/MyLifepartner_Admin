import { JwtPayload } from "jsonwebtoken";

export interface UserJwtPayload extends JwtPayload {
   id: number;
   email: string | null;
   role: string;
}

declare global {
   namespace Express {
      interface Request {
         user?: UserJwtPayload;
      }
   }
}

export {};
