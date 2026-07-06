import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
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
    * @route PATCH /api/v1/user/profile/basic-profile/:userId
    * @purpose Updates basic profile details for the authenticated user.
    */
   public updateBasicProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.userId);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const result = await this.profileService.updateBasicProfile(userId, req.body);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Basic profile updated successfully"));
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
