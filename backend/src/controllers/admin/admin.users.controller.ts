import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserSubscriptionService } from "@/interfaces/services/user.subscription.service.interface";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";
import { auditService } from "@/services/audit.service";
import { ActorType, AuditModule, AuditStatus, AuditSeverity, AuditSource } from "@prisma/client";

export class AdminUsersController {
   constructor(
      private readonly userService: IUserService,
      private readonly userSubscriptionService: IUserSubscriptionService
   ) {}

   /**
    * @route GET /api/v1/admin/users
    * @purpose Fetches all users with pagination and filters.
    */
   public getAllUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;
      const selfieStatus = typeof req.query.selfieStatus === "string" ? req.query.selfieStatus.trim() : undefined;

      const pageNumber = req.query.page ? Number(req.query.page) : undefined;
      const limitNumber = req.query.limit ? Number(req.query.limit) : undefined;

      if (pageNumber !== undefined && (!Number.isInteger(pageNumber) || pageNumber <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid page number");
      }

      if (limitNumber !== undefined && (!Number.isInteger(limitNumber) || limitNumber <= 0 || limitNumber > 100)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid limit number");
      }

      const { data, total } = await this.userService.getUsers(search, pageNumber, limitNumber, selfieStatus);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Users fetched successfully"));
   });

   /**
    * @route GET /api/v1/admin/users/:id
    * @purpose Fetches complete details of a specific user.
    */
   public getUserById = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const user = await this.userService.getCompleteUserDetailsForAdmin(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, user, "User details fetched successfully"));
   });

   /**
    * Toggles user ban status.
    *
    * @route PATCH /api/v1/admin/users/:id/ban
    */
   public toggleBanUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const result = await this.userService.toggleBanStatus(userId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.MODERATION,
         action: "TOGGLE_USER_BAN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Toggled ban status for user ID: ${userId} to ${result.isBanned}`,
         newValue: { isBanned: result.isBanned },
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User ban status updated successfully"));
   });

   /**
    * @route GET /api/v1/admin/users/suspended
    * @purpose Fetches all suspended users.
    */
   public getSuspendedUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const users = await this.userService.getSuspendedUsers();
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, users, "Suspended users fetched successfully"));
   });

   /**
    * @route GET /api/admin/users/subscriptions/grace-period
    * @purpose Fetches users whose current subscription is in grace period.
    */
   public getGracePeriodSubscriptionUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;
      const pageNumber = req.query.page ? Number(req.query.page) : undefined;
      const limitNumber = req.query.limit ? Number(req.query.limit) : undefined;

      if (pageNumber !== undefined && (!Number.isInteger(pageNumber) || pageNumber <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid page number");
      }

      if (limitNumber !== undefined && (!Number.isInteger(limitNumber) || limitNumber <= 0 || limitNumber > 100)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid limit number");
      }

      const { data, total } = await this.userService.getGracePeriodSubscriptionUsers(search, pageNumber, limitNumber);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Grace period subscription users fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/users/:id/lift-suspension
    * @purpose Lifts a user's temporary suspension.
    */
   public liftSuspension = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const result = await this.userService.liftSuspension(userId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.MODERATION,
         action: "LIFT_USER_SUSPENSION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `Lifted suspension for user ID: ${userId}`,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User suspension lifted successfully"));
   });

   /**
    * @route POST /api/v1/admin/users
    * @purpose Creates a new user.
    */
   public createUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const createPayload: CreateUserDto = req.body;

      const result = await this.userService.createUser(createPayload);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action: "CREATE_USER_BY_ADMIN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin created user: ${result.email}`,
         newValue: result,
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User created successfully"));
   });

   /**
    * @route PUT /api/v1/admin/users/:id
    * @purpose Updates a user by ID.
    */
   public updateUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);
      const updatePayload: UpdateUserDto = req.body;

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const result = await this.userService.updateUser(userId, updatePayload);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action: "UPDATE_USER_BY_ADMIN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin updated user ID: ${userId}`,
         newValue: updatePayload,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User updated successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/users/:id/founding-member
    * @purpose Toggles founding-member status.
    */
   public toggleFoundingMemberStatus = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const { user: result, previousIsFoundingMember, previousFoundingMemberSince } = await this.userService.toggleFoundingMemberStatus(userId);
      const action = result.isFoundingMember ? "GRANT_FOUNDING_MEMBER" : "REVOKE_FOUNDING_MEMBER";

      await auditService.log({
         userId,
         adminId: Number.isInteger(adminId) && adminId > 0 ? adminId : undefined,
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action,
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin ${result.isFoundingMember ? "granted" : "revoked"} founding-member status for user ID: ${userId}`,
         oldValue: { isFoundingMember: previousIsFoundingMember, foundingMemberSince: previousFoundingMemberSince },
         newValue: { isFoundingMember: result.isFoundingMember, foundingMemberSince: result.foundingMemberSince },
         metadata: {
            affectedUserId: userId,
            actingAdminId: Number.isInteger(adminId) && adminId > 0 ? adminId : null,
         },
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Founding-member status updated successfully"));
   });

   /**
    * @route PATCH /api/admin/users/:id/downgrade-grace-period
    * @purpose Manually downgrades a grace-period user to the base plan.
    */
   public downgradeGracePeriodUserToBasePlan = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const subscription = await this.userSubscriptionService.downgradeGracePeriodUserToBasePlan(userId);

      await auditService.log({
         userId,
         adminId: Number.isInteger(adminId) && adminId > 0 ? adminId : undefined,
         actorType: ActorType.ADMIN,
         module: AuditModule.SUBSCRIPTION,
         action: "MANUAL_DOWNGRADE_GRACE_PERIOD_USER",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin manually downgraded grace-period user ID: ${userId} to the base plan`,
         newValue: {
            subscriptionId: subscription.id,
            planId: subscription.planId,
            planName: subscription.plan?.name,
            status: subscription.status,
         },
         metadata: {
            affectedUserId: userId,
            actingAdminId: Number.isInteger(adminId) && adminId > 0 ? adminId : null,
         },
         entityType: "UserSubscription",
         entityId: subscription.id.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, subscription, "Grace period user downgraded to base plan successfully"));
   });



   /**
    * @route DELETE /api/v1/admin/users/:id
    * @purpose Deletes a user by ID.
    */
   public deleteUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      await this.userService.deleteUser(userId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action: "DELETE_USER_BY_ADMIN",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `Admin deleted user ID: ${userId}`,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "User deleted successfully"));
   });

   /**
    * @route GET /api/v1/admin/users/:id/selfie-url
    * @purpose Fetches user selfie verification data.
    */
   public getSelfieUrl = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const data = await this.userService.getUserSelfieData(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Selfie data fetched successfully"));
   });

   /**
    * @route GET /api/v1/admin/users/:id/images
    * @purpose Fetches uploaded profile images of a user.
    */
   public getUserImages = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const data = await this.userService.getUserImagesData(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Images fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/users/:id/verify-profile
    * @purpose Verifies user profile and selfie.
    */
   public verifyProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      const result = await this.userService.updateUser(userId, {
         isVerified: true,
         selfieStatus: "APPROVED",
      });

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.PROFILE,
         action: "VERIFY_USER_PROFILE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `Admin verified profile for user ID: ${userId}`,
         newValue: { isVerified: true, selfieStatus: "APPROVED" },
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User profile verified successfully"));
   });

   /**
    * @route GET /api/v1/admin/users/deletion-requests
    * @purpose Fetches all pending deletion requests.
    */
   public getPendingDeletionRequests = asyncHandler(async (req: AuthRequest, res: Response) => {
      const pageNumber = req.query.page ? Number(req.query.page) : undefined;
      const limitNumber = req.query.limit ? Number(req.query.limit) : undefined;

      const { data, total } = await this.userService.getPendingDeletionRequests(pageNumber, limitNumber);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Pending deletion requests fetched"));
   });

   /**
    * @route POST /api/v1/admin/users/:id/approve-deletion
    * @purpose Approves a deletion request.
    */
   public approveDeletionRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      await this.userService.approveDeletionRequest(userId, adminId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action: "APPROVE_ACCOUNT_DELETION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `Admin approved account deletion for user ID: ${userId}`,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Deletion request approved and data anonymized"));
   });

   /**
    * @route POST /api/v1/admin/users/:id/reject-deletion
    * @purpose Rejects a deletion request.
    */
   public rejectDeletionRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = Number(req.params.id);
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      await this.userService.rejectDeletionRequest(userId, adminId);

      await auditService.log({
         actorType: ActorType.ADMIN,
         module: AuditModule.ACCOUNT,
         action: "REJECT_ACCOUNT_DELETION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `Admin rejected account deletion for user ID: ${userId}`,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.ADMIN,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Deletion request rejected"));
   });

   /**
    * @route GET /api/v1/admin/users/archived
    * @purpose Fetches all archived (deleted) users
    */
   public getArchivedUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const pageNumber = req.query.page ? Number(req.query.page) : 1;
      const limitNumber = req.query.limit ? Number(req.query.limit) : 10;

      if (!Number.isInteger(pageNumber) || pageNumber <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid page number");
      }

      if (!Number.isInteger(limitNumber) || limitNumber <= 0 || limitNumber > 100) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid limit number");
      }

      const { data, total } = await this.userService.getArchivedUsers(pageNumber, limitNumber);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Archived users fetched successfully"));
   });
}
