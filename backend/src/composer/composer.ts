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
import { ImageAccessRequestRepository } from "@/repositories/image-access-request.repository";
import { ImageAssetRepository } from "@/repositories/image-asset.repository";
import { MatchRepository } from "@/repositories/match.repository";
import { PlanFeatureRepository } from "@/repositories/plan-feature.repository";
import { ProcessedRevenueCatEventRepository } from "@/repositories/processed-revenuecat-event.repository";
import { ProfileRepository } from "@/repositories/profile.repository";
import { QuestionnaireRepository } from "@/repositories/questionnaire.repository";
import { SubscriptionPlanRepository } from "@/repositories/subscription-plan.repository";
import { SubscriptionWebhookRepository } from "@/repositories/subscription-webhook.repository";
import { TransactionHistoryRepository } from "@/repositories/transaction-history.repository";
import { UserSubscriptionRepository } from "@/repositories/user-subscription.repository";
import { UserFeatureRepository } from "@/repositories/user.feature.repository";
import { UserRepository } from "@/repositories/user.repository";
import { BlockRepository } from "@/repositories/block.repository";
import { ReportRepository } from "@/repositories/report.repository";
import { ModerationRepository } from "@/repositories/moderation.repository";
import { JobRepository } from "@/repositories/job.repository";
import { NotificationRepository } from "@/repositories/notification.repository";

// ─────────────────────────────────────────────────────────────────────────────
// Infrastructure Services
// ─────────────────────────────────────────────────────────────────────────────

import { CacheService } from "@/services/cache.service";
import { EmailService } from "@/services/email.service";
import { JwtService } from "@/services/jwt.service";
import { OtpService } from "@/services/otp.service";
import { S3Service } from "@/services/s3.service";
import { ZegoService } from "@/services/zego.service";
import { BlockService } from "@/services/block.service";

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
import { ImageAccessRequestService } from "@/services/image-access-request.service";
import { ImageProcessorService } from "@/services/image-processor.service";
import { MatchService } from "@/services/match.service";
import { PrivacyImageMapperService } from "@/services/privacy-image-mapper.service";
import { PrivacyPolicyService } from "@/services/privacy-policy.service";
import { ReportService } from "@/services/report.service";
import { UserService } from "@/services/user.service";
import { AuthService } from "@/services/user/user.auth.service";
import { UserFeatureService } from "@/services/user/user.feature.service";
import { ProfileService } from "@/services/user/user.profile.service";
import { JobService } from "@/services/user/job.service";
import { TransactionHistoryService } from "@/services/user/transaction-history.service";
import { UserSubscriptionService } from "@/services/user/user.subscription.service";
import { OAuthService } from "@/services/user/user.oauth.service";

// ─────────────────────────────────────────────────────────────────────────────
// Controllers
// ─────────────────────────────────────────────────────────────────────────────

import { AdminAuthController } from "@/controllers/admin/admin.auth.controller";
import { AdminFeatureController } from "@/controllers/admin/admin.feature.controller";
import { AdminManagementController } from "@/controllers/admin/admin.management.controller";
import { AdminQuestionnaireController } from "@/controllers/admin/admin.questionnaire.controller";
import { AdminReportController } from "@/controllers/admin/admin.report.controller";
import { AdminSubscriptionController } from "@/controllers/admin/admin.subscription.controller";
import { AdminUsersController } from "@/controllers/admin/admin.users.controller";
import { ImageAssetController } from "@/controllers/image-asset.controller";

import { GuideController } from "@/controllers/guide.controller";
import { AuthController } from "@/controllers/user/auth.controller";
import { ChatController } from "@/controllers/user/chat.controller";
import { MatchController } from "@/controllers/user/match.controller";
import { ProfileController } from "@/controllers/user/profile.controller";
import { ProfileImageController } from "@/controllers/user/profile.image.controller";
import { PrivacyController } from "@/controllers/user/privacy.controller";
import { ImageAccessRequestController } from "@/controllers/user/image-access-request.controller";
import { UserController } from "@/controllers/user/user.controller";
import { JobController } from "@/controllers/user/job.controller";
import { TransactionHistoryController } from "@/controllers/user/transaction-history.controller";
import { UserSubscriptionController } from "@/controllers/user/user.subscription.controller";
import { ZegoController } from "@/controllers/user/zego.controller";
import { UserBlockController } from "@/controllers/user/user.block.controller";
import { OAuthController } from "@/controllers/user/oauth.controller";
import { NotificationController } from "@/controllers/notification.controller";
import { UserReportController } from "@/controllers/user/user.report.controller";

// ─────────────────────────────────────────────────────────────────────────────
// 1. Repository Instances
// ─────────────────────────────────────────────────────────────────────────────

export const adminRepository = new AdminRepository();
export const chatRepository = new ChatRepository();
export const guideRepository = new GuideRepository();
export const imageAccessRequestRepository = new ImageAccessRequestRepository();
export const imageAssetRepository = new ImageAssetRepository();
export const matchRepository = new MatchRepository();
export const planFeatureRepository = new PlanFeatureRepository();
export const processedRevenueCatEventRepository = new ProcessedRevenueCatEventRepository();
export const profileRepository = new ProfileRepository();
export const questionnaireRepository = new QuestionnaireRepository();
export const subscriptionPlanRepository = new SubscriptionPlanRepository();
export const subscriptionWebhookRepository = new SubscriptionWebhookRepository();
export const transactionHistoryRepository = new TransactionHistoryRepository();
export const userFeatureRepository = new UserFeatureRepository();
export const userRepository = new UserRepository();
export const jobRepository = new JobRepository();
export const reportRepository = new ReportRepository();
export const moderationRepository = new ModerationRepository();
export const blockRepository = new BlockRepository();
export const userSubscriptionRepository = new UserSubscriptionRepository();
export const notificationRepository = new NotificationRepository();

// ─────────────────────────────────────────────────────────────────────────────
// 2. Infrastructure Service Instances
// ─────────────────────────────────────────────────────────────────────────────

export const cacheService = new CacheService();
export const s3Service = new S3Service();
export const emailService = new EmailService(s3Service);
export const jwtService = new JwtService();
export const zegoService = new ZegoService();

export const otpService = new OtpService(cacheService, emailService);
export const reportService = new ReportService(s3Service, emailService, reportRepository, moderationRepository);

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
export const authService = new AuthService(userRepository, otpService, jwtService, cacheService, subscriptionPlanRepository, userSubscriptionRepository, emailService);
export const imageProcessorService = new ImageProcessorService();
export const profileService = new ProfileService(profileRepository, s3Service, imageProcessorService);
export const jobService = new JobService(jobRepository);
export const transactionHistoryService = new TransactionHistoryService(transactionHistoryRepository);
export const userSubscriptionService = new UserSubscriptionService(subscriptionPlanRepository, userSubscriptionRepository, processedRevenueCatEventRepository, userFeatureRepository, subscriptionWebhookRepository, userRepository, emailService);
export const oauthService = new OAuthService(userRepository, jwtService, subscriptionPlanRepository, userSubscriptionRepository);
export const blockService = new BlockService(blockRepository);

// Shared services
export const guideService = new GuideService(guideRepository);
export const chatService = new ChatService(chatRepository, userFeatureService, blockService);
export const privacyPolicyService = new PrivacyPolicyService();
export const privacyImageMapperService = new PrivacyImageMapperService(privacyPolicyService, s3Service);
export const imageAccessRequestService = new ImageAccessRequestService(imageAccessRequestRepository, s3Service);
export const matchService = new MatchService(matchRepository, s3Service, userFeatureService, privacyImageMapperService, imageAccessRequestService);

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
export const adminReportController = new AdminReportController(reportService);

// Shared controllers
export const guideController = new GuideController(guideService);
export const userBlockController = new UserBlockController(blockService);

// User controllers
export const authController = new AuthController(authService, userService, userSubscriptionService);
export const profileController = new ProfileController(profileService);
export const profileImageController = new ProfileImageController(profileService);
export const privacyController = new PrivacyController(profileService);
export const imageAccessRequestController = new ImageAccessRequestController(imageAccessRequestService);
export const userController = new UserController(userService);
export const jobController = new JobController(jobService);
export const transactionHistoryController = new TransactionHistoryController(transactionHistoryService);
export const matchController = new MatchController(matchService);
export const userSubscriptionController = new UserSubscriptionController(userSubscriptionService, userFeatureService);
export const chatController = new ChatController(chatService);
export const zegoController = new ZegoController(zegoService);
export const oauthController = new OAuthController(oauthService, userSubscriptionService);
export const notificationController = new NotificationController(notificationRepository);
export const userReportController = new UserReportController(reportService);

// End of composer.ts
