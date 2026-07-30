import { UserDto } from "@/dtos/user.dto";

export interface AuthTokens {
   accessToken: string;
   refreshToken: string;
}

export interface IOAuthService {
   googleSignIn(idToken: string): Promise<{ user: UserDto } & AuthTokens>;
   appleSignIn(
      identityToken: string,
      authorizationCode: string,
      platform: "ios" | "android" | "web",
      email?: string | null,
      firstName?: string | null,
      lastName?: string | null,
      nonce?: string | null
   ): Promise<{ user: UserDto } & AuthTokens>;
}
