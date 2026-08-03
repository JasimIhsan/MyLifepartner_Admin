import env from "@/config/env";
import { toUserDto } from "@/dtos/user.dto";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IUserSubscriptionRepository, SubscriptionStatus } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { IJwtService } from "@/interfaces/services/jwt.service.interface";
import { AuthTokens, IOAuthService } from "@/interfaces/services/user.oauth.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import logger from "@/utils/logger";
import bcrypt from "bcrypt";
import crypto from "crypto";
import { OAuth2Client } from "google-auth-library";
import https from "https";
import jwt from "jsonwebtoken";
import jwksClient from "jwks-rsa";

const FREE_PLAN_NAME = "FREE";
const PASSWORD_SALT_ROUNDS = 10;
const ACCESS_TOKEN_EXPIRY = "15m";
const REFRESH_TOKEN_EXPIRY = "7d";
const FREE_PLAN_DURATION_YEARS = 100;

const appleJwksClient = jwksClient({
   jwksUri: "https://appleid.apple.com/auth/keys",
   cache: true,
   cacheMaxEntries: 5,
   cacheMaxAge: 86400000, // 24 hours
   rateLimit: true,
   jwksRequestsPerMinute: 10,
   // Force IPv4 to avoid Docker NAT64 IPv6 routing failures.
   // Docker's internal DNS returns both IPv4 and a NAT64 IPv6 address for external hosts.
   // Node.js "Happy Eyeballs" prefers IPv6 which times out inside Docker networking.
   requestAgent: new https.Agent({ family: 4 }),
});

export class OAuthService implements IOAuthService {
   private googleClient: OAuth2Client;

   constructor(
      private readonly userRepository: IUserRepository,
      private readonly jwtService: IJwtService,
      private readonly subscriptionPlanRepository: ISubscriptionPlanRepository,
      private readonly userSubscriptionRepository: IUserSubscriptionRepository
   ) {
      this.googleClient = new OAuth2Client(env.GOOGLE_CLIENT_ID);
   }

   public async googleSignIn(idToken: string) {
      if (!idToken) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "ID token is required");
      }

      logger.debug(`Google Client ID: ${env.GOOGLE_CLIENT_ID}`);
      logger.debug(`Google Web Client ID: ${env.GOOGLE_WEB_CLIENT_ID}`);
      logger.debug(`ID Token: ${idToken}`);

      const validAudiences = [env.GOOGLE_CLIENT_ID, env.GOOGLE_WEB_CLIENT_ID].filter((id) => id && id.trim().length > 0);

      let payload;
      try {
         const ticket = await this.googleClient.verifyIdToken({
            idToken,
            audience: validAudiences.length === 1 ? validAudiences[0] : validAudiences,
         });
         payload = ticket.getPayload();
      } catch (error) {
         logger.error("Google verify token failed", error);
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid Google ID token");
      }

      if (!payload || !payload.email || !payload.sub) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid Google ID token payload");
      }

      const googleUserId = payload.sub;
      const email = payload.email.trim().toLowerCase();

      // 1. Check if user already exists via SocialAccount provider
      let user = await this.userRepository.findByProviderId("GOOGLE", googleUserId);

      if (!user) {
         // 2. Not found by providerId. Check by email
         user = await this.userRepository.findByEmail(email);

         if (!user) {
            // 3. Create new user account
            const randomPassword = crypto.randomBytes(16).toString("hex");
            const hashedPassword = await bcrypt.hash(randomPassword, PASSWORD_SALT_ROUNDS);

            user = await this.userRepository.create({
               email,
               password: hashedPassword,
            });

            const fullName = payload.name?.trim() || `${payload.given_name ?? ""} ${payload.family_name ?? ""}`.trim();
            if (fullName) {
               user = await this.userRepository.update(user.id, { name: fullName });
            }

            await this.assignFreePlanIfAvailable(user.id);
         }
      }

      if (user.isBanned) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
      }
      if (user.isSuspended) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
      }

      // Upsert the Google social account record (create or update updatedAt)
      await this.userRepository.upsertSocialAccount(user.id, "GOOGLE", googleUserId);

      const tokens = this.generateAuthTokens(user.id, user.email, user.role);

      return {
         user: toUserDto(user),
         ...tokens,
      };
   }

   public async appleSignIn(identityToken: string, authorizationCode: string, platform: "ios" | "android" | "web", email?: string | null, firstName?: string | null, lastName?: string | null, nonce?: string | null) {
      if (!identityToken || !authorizationCode) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Identity token and authorization code are required");
      }

      logger.debug(`Apple Sign-In on platform: ${platform}`);

      // Verify the Apple identity token using cached JWKS client
      const getKey = (header: jwt.JwtHeader, callback: jwt.SigningKeyCallback) => {
         appleJwksClient.getSigningKey(header.kid, (err, key) => {
            if (err) {
               logger.error("Error fetching Apple signing key", err);
               return callback(err);
            }
            const signingKey = key?.getPublicKey();
            callback(null, signingKey);
         });
      };

      const expectedClientId = platform === "ios" ? env.APPLE_IOS_CLIENT_ID : env.APPLE_SERVICE_ID;

      let decodedToken: jwt.JwtPayload;

      try {
         decodedToken = await new Promise((resolve, reject) => {
            jwt.verify(
               identityToken,
               getKey,
               {
                  algorithms: ["RS256"],
                  issuer: "https://appleid.apple.com",
                  audience: expectedClientId,
               },
               (err, decoded) => {
                  if (err) return reject(err);
                  resolve(decoded as jwt.JwtPayload);
               }
            );
         });
      } catch (error) {
         logger.error("Apple token verification failed", error);
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid Apple identity token");
      }

      if (!decodedToken.sub) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Apple identity token missing sub");
      }

      // If nonce is provided from frontend, we should verify it against the one in token
      if (nonce && decodedToken.nonce) {
         const hashedNonce = crypto.createHash("sha256").update(nonce).digest("hex");
         if (hashedNonce !== decodedToken.nonce) {
            throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Nonce mismatch");
         }
      }

      const appleUserId = decodedToken.sub;
      const verifiedEmail = decodedToken.email?.trim().toLowerCase();
      const isEmailVerified = decodedToken.email_verified === true || decodedToken.email_verified === "true";

      // 1. Check if user already exists via SocialAccount provider
      let user = await this.userRepository.findByProviderId("APPLE", appleUserId);

      if (!user) {
         // 2. Not found by providerId. Check if they have a verified email that matches an existing account
         if (verifiedEmail && isEmailVerified) {
            user = await this.userRepository.findByEmail(verifiedEmail);
         }

         if (!user) {
            // Create new account.
            const randomPassword = crypto.randomBytes(16).toString("hex");
            const hashedPassword = await bcrypt.hash(randomPassword, PASSWORD_SALT_ROUNDS);

            // Apple always includes an email in the JWT (either the user's real address
            // or their actual Apple private relay address like xyz@privaterelay.appleid.com).
            // Fall back to the client-provided email (sent only on first sign-in) if the
            // JWT email is somehow absent. Never construct a fake relay address.
            const clientEmail = email?.trim().toLowerCase() ?? null;
            const finalEmail = verifiedEmail ?? clientEmail;

            if (!finalEmail) {
               // This should be extremely rare: Apple always provides email in the JWT.
               throw new ApiError(HTTP_STATUS.UNPROCESSABLE_ENTITY, "Unable to retrieve email from Apple sign-in. Please try again or use a different sign-in method.");
            }

            user = await this.userRepository.create({
               email: finalEmail,
               password: hashedPassword,
            });

            if (firstName || lastName) {
               const fullName = `${firstName ?? ""} ${lastName ?? ""}`.trim();
               if (fullName) {
                  user = await this.userRepository.update(user.id, { name: fullName });
               }
            }

            await this.assignFreePlanIfAvailable(user.id);
         }
      }

      if (user.isBanned) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account has been permanently banned.");
      }
      if (user.isSuspended) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Your account is temporarily suspended.");
      }

      // Upsert the Apple social account record (create or update updatedAt)
      await this.userRepository.upsertSocialAccount(user.id, "APPLE", appleUserId);

      const tokens = this.generateAuthTokens(user.id, user.email, user.role);

      return {
         user: toUserDto(user),
         ...tokens,
      };
   }

   private async assignFreePlanIfAvailable(userId: number): Promise<void> {
      const freePlan = await this.subscriptionPlanRepository.getPlanByName(FREE_PLAN_NAME);

      if (!freePlan) {
         return;
      }

      const startDate = new Date();
      const endDate = this.getFreePlanEndDate(startDate);

      await this.userSubscriptionRepository.createUserSubscription({
         user: {
            connect: { id: userId },
         },
         plan: {
            connect: { id: freePlan.id },
         },
         startDate,
         endDate,
         status: SubscriptionStatus.ACTIVE,
         willRenew: false,
      });
   }

   private getFreePlanEndDate(startDate: Date): Date {
      const endDate = new Date(startDate);
      endDate.setFullYear(endDate.getFullYear() + FREE_PLAN_DURATION_YEARS);
      return endDate;
   }

   private generateAuthTokens(id: number, email: string | null, role: string): AuthTokens {
      const payload = { id, email, role };
      return {
         accessToken: this.jwtService.signAccess(payload, ACCESS_TOKEN_EXPIRY),
         refreshToken: this.jwtService.signRefresh(payload, REFRESH_TOKEN_EXPIRY),
      };
   }
}
