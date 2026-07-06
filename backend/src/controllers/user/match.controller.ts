import { IMatchService, SwipeAction } from "@/interfaces/services/match.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class MatchController {
   constructor(private readonly matchService: IMatchService) {}

   /**
    * @route GET /api/v1/user/match/recommendations
    * @purpose Fetches recommended match profiles for the authenticated user.
    */
   public getRecommendations = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const recommendations = await this.matchService.getRecommendations(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, recommendations, "Recommendations fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/match/interests/sent
    * @purpose Fetches profiles where the authenticated user sent interest.
    */
   public getSentInterests = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const sentInterests = await this.matchService.getSentInterests(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, sentInterests, "Sent interests fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/match/interests/received
    * @purpose Fetches profiles that sent interest to the authenticated user.
    */
   public getReceivedInterests = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const receivedInterests = await this.matchService.getReceivedInterests(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, receivedInterests, "Received interests fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/match/mutual-matches
    * @purpose Fetches mutual matches for the authenticated user.
    */
   public getMutualMatches = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const mutualMatches = await this.matchService.getMutualMatches(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, mutualMatches, "Mutual matches fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/match/profile/:profileId
    * @purpose Fetches match candidate profile details.
    */
   public getProfileDetail = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const profileId = this.getRequiredPositiveNumber(req.params.profileId, "Invalid profile ID");

      const detail = await this.matchService.getProfileDetail(userId, profileId);

      if (!detail) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Profile not found");
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, detail, "Profile detail fetched successfully"));
   });

   /**
    * @route POST /api/v1/user/match/swipe
    * @purpose Records a swipe action on another profile.
    */
   public swipeProfile = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const targetProfileId = this.getRequiredPositiveNumber(req.body.targetProfileId, "Target profile ID is required");
      const action = this.getSwipeAction(req.body.action);


      await this.matchService.swipeProfile({
         userId,
         targetProfileId,
         action,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Swipe recorded successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: Request): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Extracts and validates a positive number.
    */
   private getRequiredPositiveNumber(value: unknown, errorMessage: string): number {
      const numberValue = Number(value);

      if (!Number.isInteger(numberValue) || numberValue <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return numberValue;
   }

   /**
    * Extracts and validates swipe action.
    */
   private getSwipeAction(value: unknown): SwipeAction {
      if (typeof value !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Swipe action is required");
      }

      const validActions: SwipeAction[] = [SwipeAction.LEFT, SwipeAction.RIGHT, SwipeAction.UP];

      if (!validActions.includes(value as SwipeAction)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, `Swipe action must be one of: ${validActions.join(", ")}`);
      }

      return value as SwipeAction;
   }
}
