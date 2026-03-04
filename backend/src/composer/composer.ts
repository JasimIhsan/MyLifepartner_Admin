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
import { ProfileRepository } from "@/repositories/profile.repository";
import { QuestionnaireRepository } from "@/repositories/questionnaire.repository";
import { UserRepository } from "@/repositories/user.repository";

export const adminRepository = new AdminRepository();
export const userRepository = new UserRepository();
export const profileRepository = new ProfileRepository();
export const questionnaireRepository = new QuestionnaireRepository();

// ─── 2. Infrastructure / Utility Services ────────────────────────────────────
import { CacheService } from "@/services/cache.service";
import { EmailService } from "@/services/email.service";
import { OtpService } from "@/services/otp.service";
import { S3Service } from "@/services/s3.service";

export const cacheService = new CacheService();
export const emailService = new EmailService();
export const otpService = new OtpService(cacheService);
export const s3Service = new S3Service();

// ─── 3. Domain Services ──────────────────────────────────────────────────────
import { AdminAuthService } from "@/services/admin/admin.auth.service";
import { AdminManagementService } from "@/services/admin/admin.management.service";
import { AdminQuestionnaireService } from "@/services/admin/admin.questionnaire.service";
import { UserService } from "@/services/user.service";
import { AuthService } from "@/services/user/user.auth.service";
import { ProfileService } from "@/services/user/user.profile.service";

// Admin services
export const adminAuthService = new AdminAuthService(adminRepository);
export const adminManagementService = new AdminManagementService(adminRepository);
export const adminQuestionnaireService = new AdminQuestionnaireService(questionnaireRepository);

// User services
export const userService = new UserService(userRepository);
export const authService = new AuthService(userService, otpService, emailService);
export const profileService = new ProfileService(profileRepository);

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

// User controllers
export const authController = new AuthController(authService);
export const profileController = new ProfileController(profileService);
export const profileImageController = new ProfileImageController(profileService, s3Service);
export const userController = new UserController(userService);
