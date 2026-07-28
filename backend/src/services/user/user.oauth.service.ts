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

const FREE_PLAN_NAME = "FREE";
const PASSWORD_SALT_ROUNDS = 10;
const ACCESS_TOKEN_EXPIRY = "15m";
const REFRESH_TOKEN_EXPIRY = "7d";
const FREE_PLAN_DURATION_YEARS = 100;

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

      if (!payload || !payload.email) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Invalid Google ID token payload");
      }

      const email = payload.email.trim().toLowerCase();
      const existingUser = await this.userRepository.findByEmail(email);

      if (existingUser) {
         // User exists, just log them in
         const tokens = this.generateAuthTokens(existingUser.id, existingUser.email, existingUser.role);
         return {
            user: toUserDto(existingUser),
            ...tokens,
         };
      }

      // User doesn't exist, create account with a random password
      const randomPassword = crypto.randomBytes(16).toString("hex");
      const hashedPassword = await bcrypt.hash(randomPassword, PASSWORD_SALT_ROUNDS);

      const user = await this.userRepository.create({
         email,
         password: hashedPassword,
      });

      await this.assignFreePlanIfAvailable(user.id);

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
