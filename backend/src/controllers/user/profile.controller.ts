import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { auditService } from "@/services/audit.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { ActorType, AuditModule, AuditSeverity, AuditSource, AuditStatus } from "@prisma/client";
import { Request, Response } from "express";

export class ProfileController {
   constructor(private readonly profileService: IProfileService) {}

   /**
    * @route GET /api/v1/user/profile/sections
    * @purpose Fetches questionnaire sections for profile setup.
    */
   public getSections = asyncHandler(async (req: Request, res: Response) => {
      const { isPrimary } = req.query;

      const isPrimaryBool = isPrimary === "true" ? true : isPrimary === "false" ? false : undefined;

      const data = await this.profileService.getSections(isPrimaryBool);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Sections fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/profile/questions/:userId
    * @purpose Fetches profile questions for the authenticated user.
    */
   public getQuestions = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);
      const sectionOrder = req.query.sectionOrder ? Number(req.query.sectionOrder) : undefined;

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      if (sectionOrder !== undefined && (!Number.isInteger(sectionOrder) || sectionOrder <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid section order");
      }

      const data = sectionOrder ? await this.profileService.getQuestionsBySectionOrder(sectionOrder, userId) : await this.profileService.getProfileStructure(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Questions fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/profile/answers/:userId
    * @purpose Fetches answers submitted by the authenticated user.
    */
   public getAnswers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const data = await this.profileService.getUserAnswers(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Answers fetched successfully"));
   });

   /**
    * @route POST /api/v1/user/profile/questions/save-answer/:userId/:questionId
    * @purpose Saves an answer for a profile question.
    */
   public saveAnswer = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);
      const questionId = Number(req.params.questionId);
      const { answer } = req.body;

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      if (!Number.isInteger(questionId) || questionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid question ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      if (answer === undefined || answer === null || answer === "") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "You need to select an answer to proceed");
      }

      const result = await this.profileService.saveAnswer(userId, questionId, answer);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "SAVE_PROFILE_ANSWER",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User saved answer for question ID: ${questionId}`,
         newValue: { answer },
         entityType: "UserAnswer",
         entityId: questionId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Answer saved successfully"));
   });

   /**
    * @route PATCH /api/v1/user/profile/complete/:userId
    * @purpose Marks profile setup as complete for the authenticated user.
    */
   public completeProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.completeProfile(userId);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "COMPLETE_PROFILE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User completed profile setup`,
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Profile completed successfully"));
   });

   /**
    * @route GET /api/v1/user/profile/completion-status/:userId
    * @purpose Fetches profile completion status for the authenticated user.
    */
   public getCompletionStatus = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.getProfileCompletionStatus(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Profile completion status fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/user/profile/update/:userId
    * @purpose Updates profile details for the authenticated user.
    */
   public updateProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.updateProfile(userId, req.body);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "UPDATE_PROFILE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User updated profile`,
         newValue: req.body,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Profile updated successfully"));
   });

   /**
    * @route GET /api/v1/user/profile/partner-preference/:userId
    * @purpose Fetches partner preference details for the authenticated user.
    */
   public getPartnerPreference = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.getPartnerPreference(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Partner preference fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/user/profile/partner-preference/:userId
    * @purpose Updates partner preference details for the authenticated user.
    */
   public updatePartnerPreference = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.updatePartnerPreference(userId, req.body);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.PROFILE,
         action: "UPDATE_PARTNER_PREFERENCE",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User updated partner preferences`,
         newValue: req.body,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Partner preference updated successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Ensures authenticated user owns the requested resource.
    */
   private ensureUserOwnsResource(resourceUserId: number, authUserId: number): void {
      if (resourceUserId !== authUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Forbidden");
      }
   }
}
