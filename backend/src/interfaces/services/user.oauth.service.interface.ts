import { UserDto } from "@/dtos/user.dto";

export interface AuthTokens {
   accessToken: string;
   refreshToken: string;
}

export type OAuthResponse = 
   | { action: "LOGIN"; user: UserDto; accessToken: string; refreshToken: string }
   | { action: "REQUIRE_CONSENT"; email: string; firstName?: string; lastName?: string };

export interface IOAuthConsent {
   termsAccepted?: boolean;
   privacyAcknowledged?: boolean;
   termsVersion?: string;
   privacyVersion?: string;
}

export interface IOAuthService {
   googleSignIn(idToken: string, consent?: IOAuthConsent): Promise<OAuthResponse>;
   appleSignIn(
      identityToken: string,
      authorizationCode: string,
      platform: "ios" | "android" | "web",
      email?: string | null,
      firstName?: string | null,
      lastName?: string | null,
      nonce?: string | null,
      consent?: IOAuthConsent
   ): Promise<OAuthResponse>;
}
