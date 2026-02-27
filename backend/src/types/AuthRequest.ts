import { Request } from "express";

export interface AuthRequest extends Request {
   user: {
      id: number;
      mobileNumber: string;
      email?: string;
      [key: string]: any;
   };
}
