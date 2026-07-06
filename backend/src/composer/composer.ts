/**
 * services.composer.ts
 *
 * Central Dependency Injection Composer
 * ------------------------------------
 * This file is the single source of truth for wiring up the application.
 *
 * Dependency order:
 * 1. Repositories
 * 2. Infrastructure Services
 * 3. Domain Services
 * 4. Controllers
 */

// ─────────────────────────────────────────────────────────────────────────────
// Repositories
// ─────────────────────────────────────────────────────────────────────────────

import { AdminRepository } from "@/repositories/admin.repository";
import { ChatRepository } from "@/repositories/chat.repository";
import { GuideRepository } from "@/repositories/guide.repository";
import { ImageAssetRepository } from "@/repositories/image-asset.repository";
import { MatchRepository } from "@/repositories/match.repository";
import { PlanFeatureRepository } from "@/repositories/plan-feature.repository";
import { ProcessedRevenueCatEventRepository } from "@/repositories/processed-revenuecat-event.repository";
import { ProfileRepository } from "@/repositories/profile.repository";
import { QuestionnaireRepository } from "@/repositories/questionnaire.repository";
import { SubscriptionPlanRepository } from "@/repositories/subscription-plan.repository";
import { UserSubscriptionRepository } from "@/repositories/user-subscription.repository";
import { UserFeatureRepository } from "@/repositories/user.feature.repository";
import { UserRepository } from "@/repositories/user.repository";

// ─────────────────────────────────────────────────────────────────────────────
// Infrastructure Services
// ─────────────────────────────────────────────────────────────────────────────

import { CacheService } from "@/services/cache.service";
import { EmailService } from "@/services/email.service";
import { JwtService } from "@/services/jwt.service";
import { OtpService } from "@/services/otp.service";
import { S3Service } from "@/services/s3.service";
import { ZegoService } from "@/services/zego.service";

// ─────────────────────────────────────────────────────────────────────────────
// Domain Services
// ─────────────────────────────────────────────────────────────────────────────

import { AdminAuthService } from "@/services/admin/admin.auth.service";
import { AdminFeatureService } from "@/services/admin/admin.feature.service";
import { AdminManagementService } from "@/services/admin/admin.management.service";
import { AdminQuestionnaireService } from "@/services/admin/admin.questionnaire.service";
import { AdminSubscriptionService } from "@/services/admin/admin.subscription.service";
import { ImageAssetService } from "@/services/admin/image-asset.service";

import { ChatService } from "@/services/chat.service";
import { GuideService } from "@/services/guide.service";
import { MatchService } from "@/services/match.service";
import { UserService } from "@/services/user.service";
import { AuthService } from "@/services/user/user.auth.service";
import { UserFeatureService } from "@/services/user/user.feature.service";
import { ProfileService } from "@/services/user/user.profile.service";
import { UserSubscriptionService } from "@/services/user/user.subscription.service";

// ─────────────────────────────────────────────────────────────────────────────
// Controllers
// ─────────────────────────────────────────────────────────────────────────────

import { AdminAuthController } from "@/controllers/admin/admin.auth.controller";
import { AdminFeatureController } from "@/controllers/admin/admin.feature.controller";
import { AdminManagementController } from "@/controllers/admin/admin.management.controller";
import { AdminQuestionnaireController } from "@/controllers/admin/admin.questionnaire.controller";
import { AdminSubscriptionController } from "@/controllers/admin/admin.subscription.controller";
import { AdminUsersController } from "@/controllers/admin/admin.users.controller";
import { ImageAssetController } from "@/controllers/admin/image-asset.controller";

import { GuideController } from "@/controllers/guide.controller";
import { AuthController } from "@/controllers/user/auth.controller";
import { ChatController } from "@/controllers/user/chat.controller";
import { MatchController } from "@/controllers/user/match.controller";
import { ProfileController } from "@/controllers/user/profile.controller";
import { ProfileImageController } from "@/controllers/user/profile.image.controller";
import { UserController } from "@/controllers/user/user.controller";
import { UserSubscriptionController } from "@/controllers/user/user.subscription.controller";
import { ZegoController } from "@/controllers/user/zego.controller";

// ─────────────────────────────────────────────────────────────────────────────
// 1. Repository Instances
// ─────────────────────────────────────────────────────────────────────────────

export const adminRepository = new AdminRepository();
export const chatRepository = new ChatRepository();
export const guideRepository = new GuideRepository();
export const imageAssetRepository = new ImageAssetRepository();
export const matchRepository = new MatchRepository();
export const planFeatureRepository = new PlanFeatureRepository();
export const processedRevenueCatEventRepository = new ProcessedRevenueCatEventRepository();
export const profileRepository = new ProfileRepository();
export const questionnaireRepository = new QuestionnaireRepository();
export const subscriptionPlanRepository = new SubscriptionPlanRepository();
export const userFeatureRepository = new UserFeatureRepository();
export const userRepository = new UserRepository();
export const userSubscriptionRepository = new UserSubscriptionRepository();

// ─────────────────────────────────────────────────────────────────────────────
// 2. Infrastructure Service Instances
// ─────────────────────────────────────────────────────────────────────────────

export const cacheService = new CacheService();
export const emailService = new EmailService();
export const jwtService = new JwtService();
export const s3Service = new S3Service();
export const zegoService = new ZegoService();

export const otpService = new OtpService(cacheService, emailService);

// ─────────────────────────────────────────────────────────────────────────────
// 3. Domain Service Instances
// ─────────────────────────────────────────────────────────────────────────────

// Admin services
export const adminAuthService = new AdminAuthService(adminRepository, jwtService);
export const adminManagementService = new AdminManagementService(adminRepository);
export const adminQuestionnaireService = new AdminQuestionnaireService(questionnaireRepository);
export const adminSubscriptionService = new AdminSubscriptionService(subscriptionPlanRepository, planFeatureRepository);
export const adminFeatureService = new AdminFeatureService();
export const imageAssetService = new ImageAssetService(imageAssetRepository, s3Service);

// User services
export const userService = new UserService(userRepository, s3Service);
export const userFeatureService = new UserFeatureService(userFeatureRepository);
export const authService = new AuthService(userRepository, otpService, jwtService, cacheService, subscriptionPlanRepository, userSubscriptionRepository);
export const profileService = new ProfileService(profileRepository);
export const userSubscriptionService = new UserSubscriptionService(subscriptionPlanRepository, userSubscriptionRepository, processedRevenueCatEventRepository, userFeatureRepository);

// Shared services
export const guideService = new GuideService(guideRepository);
export const chatService = new ChatService(chatRepository);
export const matchService = new MatchService(matchRepository, s3Service, userFeatureService);

// ─────────────────────────────────────────────────────────────────────────────
// 4. Controller Instances
// ─────────────────────────────────────────────────────────────────────────────

// Admin controllers
export const adminAuthController = new AdminAuthController(adminAuthService);
export const adminManagementController = new AdminManagementController(adminManagementService);
export const adminQuestionnaireController = new AdminQuestionnaireController(adminQuestionnaireService);
export const adminSubscriptionController = new AdminSubscriptionController(adminSubscriptionService);
export const adminFeatureController = new AdminFeatureController(adminFeatureService);
export const imageAssetController = new ImageAssetController(imageAssetService);
export const adminUsersController = new AdminUsersController(userService);

// Shared controllers
export const guideController = new GuideController(guideService);

// User controllers
export const authController = new AuthController(authService, userService);
export const profileController = new ProfileController(profileService);
export const profileImageController = new ProfileImageController(profileService, s3Service);
export const userController = new UserController(userService);
export const matchController = new MatchController(matchService);
export const userSubscriptionController = new UserSubscriptionController(userSubscriptionService, userFeatureService);
export const chatController = new ChatController(chatService, userFeatureService);
export const zegoController = new ZegoController(zegoService);
