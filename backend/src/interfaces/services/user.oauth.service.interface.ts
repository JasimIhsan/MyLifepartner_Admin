import { UserDto } from "@/dtos/user.dto";

export interface AuthTokens {
   accessToken: string;
   refreshToken: string;
}

export interface IOAuthService {
   googleSignIn(idToken: string): Promise<{ user: UserDto } & AuthTokens>;
}
