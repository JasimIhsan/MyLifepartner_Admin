import env from "@/config/env";
import { IOAuthService } from "@/interfaces/services/user.oauth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class OAuthController {
   constructor(private readonly oauthService: IOAuthService) {}

   /**
    * @route POST /api/v1/user/oauth/google
    * @purpose Authenticate user with Google ID Token.
    */
   public googleSignIn = asyncHandler(async (req: Request, res: Response) => {
      const idToken = this.getRequiredString(req.body.idToken, "ID token is required");

      const result = await this.oauthService.googleSignIn(idToken);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Google sign-in successful"));
   });

   /**
    * @route POST /api/v1/user/oauth/apple
    * @purpose Authenticate user with Apple ID Token.
    */
   public appleSignIn = asyncHandler(async (req: Request, res: Response) => {
      const identityToken = this.getRequiredString(req.body.identityToken, "Identity token is required");
      const authorizationCode = this.getRequiredString(req.body.authorizationCode, "Authorization code is required");

      if (!["ios", "android", "web"].includes(req.body.platform)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid platform");
      }

      const platform = req.body.platform as "ios" | "android" | "web";
      const { email, firstName, lastName, nonce } = req.body;

      const result = await this.oauthService.appleSignIn(identityToken, authorizationCode, platform, email, firstName, lastName, nonce);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Apple sign-in successful"));
   });

   /**
    * @route POST /api/v1/user/oauth/apple/callback
    * @route GET  /api/v1/user/oauth/apple/callback
    * @purpose Apple Sign In callback — handles both Web and Android.
    *
    * Platform behaviour:
    *  • Android (Chrome Custom Tab): Apple form-POSTs credentials here.
    *    We redirect 302 to a custom URI scheme (`lifepartneragain://apple-callback?...`)
    *    so Android's intent system routes it to the sign_in_with_apple package's
    *    SignInWithAppleCallback activity, which resolves the Flutter Future.
    *    (Custom schemes are intercepted by Chrome Custom Tab without App Links verification.)
    *
    *  • Web (popup window): Apple form-POSTs credentials here.
    *    We return an HTML page that uses `window.opener.postMessage` to send the
    *    credentials back to the Flutter Web app that opened the popup.
    */
   public appleCallback = asyncHandler(async (req: Request, res: Response) => {
      const userAgent = req.headers["user-agent"] ?? "";
      const isAndroid = /android/i.test(userAgent);

      if (isAndroid && req.method === "POST") {
         // ── Android path ──────────────────────────────────────────────────────
         // Apple sent the authorization result in the POST body (form_post mode).
         // Chrome Custom Tab has no window.opener; postMessage won't work.
         // Instead, redirect to a custom URI scheme that the Android intent system
         // intercepts and hands to SignInWithAppleCallback (sign_in_with_apple pkg).
         const { code, id_token, state, user, error } = req.body as Record<string, string | undefined>;

         const params = new URLSearchParams();
         if (code) params.set("code", code);
         if (id_token) params.set("id_token", id_token);
         if (state) params.set("state", state);
         if (user) params.set("user", user); // JSON string from Apple
         if (error) params.set("error", error);

         // lifepartneragain://apple-callback matches the SignInWithAppleCallback intent filter.
         const callbackUri = `lifepartneragain://apple-callback?${params.toString()}`;
         return res.redirect(302, callbackUri);
      }

      // ── Web path ──────────────────────────────────────────────────────────────
      // Safely embed req.body as JSON in the script tag.
      // We replace </script> injection vectors by unicode-escaping < > & —
      // this is the standard technique to embed JSON inside an HTML <script> block.
      const safeJson = JSON.stringify(req.body).replace(/</g, "\\u003c").replace(/>/g, "\\u003e").replace(/&/g, "\\u0026");

      // Restrict postMessage to the configured frontend origin.
      // FRONTEND_URL must be set in production to the Flutter Web app's origin.
      // Defaults to "*" in development only.
      const targetOrigin = JSON.stringify(env.FRONTEND_URL);

      return res.status(HTTP_STATUS.OK).send(`<!DOCTYPE html>
<html>
<head>
   <meta charset="UTF-8" />
   <title>Apple Sign In Callback</title>
</head>
<body>
   <script>
      (function () {
         var payload = ${safeJson};
         var targetOrigin = ${targetOrigin};
         if (window.opener && typeof window.opener.postMessage === 'function') {
            window.opener.postMessage(payload, targetOrigin);
         }
         window.close();
      })();
   </script>
   <p>Authentication complete. You can close this window.</p>
</body>
</html>`);
   });

   /**
    * Extracts and validates a required string value.
    */
   private getRequiredString(value: unknown, errorMessage: string): string {
      if (typeof value !== "string" || value.trim().length === 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return value.trim();
   }
}
