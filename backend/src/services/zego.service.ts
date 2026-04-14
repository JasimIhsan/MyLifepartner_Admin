import env from "@/config/env";
import { generateToken04 } from "@/utils/zegoServerAssistant";

export class ZegoService {
   private readonly appId: number;
   private readonly serverSecret: string;
   private readonly tokenExpirySeconds = 3600; // 1 hour

   constructor() {
      this.appId = env.ZEGO_APP_ID;
      this.serverSecret = env.ZEGO_SERVER_SECRET;
   }

   /**
    * Generate a ZEGOCLOUD access token for a given user.
    * The userId here is the app's internal user ID cast to string.
    */
   generateToken(userId: string): string {
      return generateToken04(
         this.appId,
         userId,
         this.serverSecret,
         this.tokenExpirySeconds,
      );
   }
}
