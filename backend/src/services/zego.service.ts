import env from "@/config/env";
import { generateToken04 } from "@/utils/zegoServerAssistant";

const ZEGO_TOKEN_EXPIRY_SECONDS = 60 * 60;

export class ZegoService {
   private readonly appId: number;
   private readonly serverSecret: string;

   constructor() {
      this.appId = env.ZEGO_APP_ID;
      this.serverSecret = env.ZEGO_SERVER_SECRET;
   }

   /**
    * Generates a ZEGOCLOUD access token.
    *
    * @param userId - User ID.
    * @returns ZEGOCLOUD access token.
    */
   generateToken(userId: string): string {
      return generateToken04(this.appId, userId, this.serverSecret, ZEGO_TOKEN_EXPIRY_SECONDS);
   }
}
