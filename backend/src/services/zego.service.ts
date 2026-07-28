import env from "@/config/env";
import { generateToken04 } from "@/utils/zegoServerAssistant";
import { ApiError } from "@/utils/ApiError";

/**
 * Token lifetime — 3 hours gives a comfortable buffer for long calls while
 * remaining well below the maximum allowed by ZEGOCLOUD (24 h).
 * The client should proactively renew at the 2h45m mark via /zego/renew-token.
 */
const ZEGO_TOKEN_EXPIRY_SECONDS = 3 * 60 * 60; // 3 hours

export class ZegoService {
   private readonly appId: number;
   private readonly serverSecret: string;

   constructor() {
      this.appId = env.ZEGO_APP_ID;
      this.serverSecret = env.ZEGO_SERVER_SECRET;
   }

   private assertConfigured(): void {
      if (!this.appId || !this.serverSecret) {
         throw new ApiError(500, "ZEGOCLOUD APP ID or Server Secret is not configured on the server.");
      }
   }

   /**
    * Generates a new ZEGOCLOUD access token for the given user.
    * Used on first login and whenever a fresh token is needed.
    *
    * @param userId - Authenticated user ID (string).
    * @returns Signed ZEGOCLOUD token valid for 3 hours.
    */
   generateToken(userId: string): string {
      this.assertConfigured();
      return generateToken04(this.appId, userId, this.serverSecret, ZEGO_TOKEN_EXPIRY_SECONDS);
   }

   /**
    * Generates a renewed ZEGOCLOUD token for an already-logged-in user.
    * Functionally identical to generateToken() but semantically distinct —
    * the client calls this mid-session to refresh before the current token expires.
    *
    * @param userId - Authenticated user ID (string).
    * @returns Fresh signed ZEGOCLOUD token valid for another 3 hours.
    */
   renewToken(userId: string): string {
      this.assertConfigured();
      return generateToken04(this.appId, userId, this.serverSecret, ZEGO_TOKEN_EXPIRY_SECONDS);
   }
}
