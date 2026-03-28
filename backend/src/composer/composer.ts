/**
 * services.composer.ts
 *
 * Central Dependency Injection Composer
 * ----------------------------------------
 * This file is the single source of truth for wiring up the entire
 * application dependency graph. All repositories, services, and
 * controllers are instantiated here and exported as ready-to-use
 * singletons.
 *
 * Layering order (dependencies satisfied before dependents):
 *   1. Repositories        – depend only on Prisma/Redis (infrastructure)
 *   2. Infrastructure Svcs – CacheService, EmailService, S3Service
 *   3. Domain Services     – depend on repositories / infrastructure services
 *   4. Controllers         – depend on domain services
 */

// ─── 1. Repositories ────────────────────────────────────────────────────────
import { AdminRepository } from "@/repositories/admin.repository";
import { MatchRepository } from "@/repositories/match.repository";
import { ProfileRepository } from "@/repositories/profile.repository";
import { QuestionnaireRepository } from "@/repositories/questionnaire.repository";
import { SubscriptionRepository } from "@/repositories/subscription.repository";
import { UserRepository } from "@/repositories/user.repository";
import { UserFeatureRepository } from "@/repositories/user.feature.repository";

export const adminRepository = new AdminRepository();
export const userRepository = new UserRepository();
export const userFeatureRepository = new UserFeatureRepository();
export const profileRepository = new ProfileRepository();
export const questionnaireRepository = new QuestionnaireRepository();
export const subscriptionRepository = new SubscriptionRepository();
export const matchRepository = new MatchRepository();

// ─── 2. Infrastructure / Utility Services ────────────────────────────────────
import { CacheService } from "@/services/cache.service";
import { EmailService } from "@/services/email.service";
import { JwtService } from "@/services/jwt.service";
import { OtpService } from "@/services/otp.service";
import { S3Service } from "@/services/s3.service";

export const cacheService = new CacheService();
export const emailService = new EmailService();
export const jwtService = new JwtService();
export const otpService = new OtpService(cacheService, emailService);
export const s3Service = new S3Service();

// ─── 3. Domain Services ──────────────────────────────────────────────────────
import { AdminAuthService } from "@/services/admin/admin.auth.service";
import { AdminManagementService } from "@/services/admin/admin.management.service";
import { AdminQuestionnaireService } from "@/services/admin/admin.questionnaire.service";
import { UserService } from "@/services/user.service";
import { AuthService } from "@/services/user/user.auth.service";
import { ProfileService } from "@/services/user/user.profile.service";
import { UserFeatureService } from "@/services/user/user.feature.service";

// Admin services
export const adminAuthService = new AdminAuthService(adminRepository, jwtService);
export const adminManagementService = new AdminManagementService(adminRepository);
export const adminQuestionnaireService = new AdminQuestionnaireService(questionnaireRepository);

import { AdminSubscriptionService } from "@/services/admin/admin.subscription.service";
export const adminSubscriptionService = new AdminSubscriptionService(subscriptionRepository);

import { AdminFeatureService } from "@/services/admin/admin.feature.service";
export const adminFeatureService = new AdminFeatureService();

// User services
export const userService = new UserService(userRepository);
export const userFeatureService = new UserFeatureService(userFeatureRepository);
export const authService = new AuthService(userRepository, userService, otpService, emailService, jwtService, cacheService, userFeatureService, subscriptionRepository);
export const profileService = new ProfileService(profileRepository);

import { MatchService } from "@/services/match.service";
export const matchService = new MatchService(matchRepository, s3Service, userFeatureService);

import { UserSubscriptionService } from "@/services/user/user.subscription.service";
export const userSubscriptionService = new UserSubscriptionService(subscriptionRepository, userFeatureRepository);

// ─── 4. Controllers ───────────────────────────────────────────────────────────
import { AdminAuthController } from "@/controllers/admin/admin.auth.controller";
import { AdminManagementController } from "@/controllers/admin/admin.management.controller";
import { AdminQuestionnaireController } from "@/controllers/admin/admin.questionnaire.controller";
import { AdminUsersController } from "@/controllers/admin/admin.users.controller";
import { AuthController } from "@/controllers/user/auth.controller";
import { ProfileController } from "@/controllers/user/profile.controller";
import { ProfileImageController } from "@/controllers/user/profile.image.controller";
import { UserController } from "@/controllers/user/user.controller";

// Admin controllers
export const adminAuthController = new AdminAuthController(adminAuthService);
export const adminManagementController = new AdminManagementController(adminManagementService);
export const adminQuestionnaireController = new AdminQuestionnaireController(adminQuestionnaireService);
export const adminUsersController = new AdminUsersController(userService);

import { AdminSubscriptionController } from "@/controllers/admin/admin.subscription.controller";
export const adminSubscriptionController = new AdminSubscriptionController(adminSubscriptionService);

import { AdminFeatureController } from "@/controllers/admin/admin.feature.controller"; // New
export const adminFeatureController = new AdminFeatureController(adminFeatureService); // New

// User controllers
export const authController = new AuthController(authService, userService);
export const profileController = new ProfileController(profileService);
export const profileImageController = new ProfileImageController(profileService, s3Service);
export const userController = new UserController(userService);

import { MatchController } from "@/controllers/user/match.controller";
export const matchController = new MatchController(matchService);

import { UserSubscriptionController } from "@/controllers/user/user.subscription.controller";
export const userSubscriptionController = new UserSubscriptionController(userSubscriptionService);
