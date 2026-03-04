import { IProfileService } from "@/interfaces/services/user.profile.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

export class ProfileController {
   constructor(private profileService: IProfileService) {}

   public getQuestions = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId;
      const { sectionOrder } = req.query;

      if (!userId) throw new ApiError(401, "Unauthorized");

      let data;
      if (sectionOrder) {
         data = await this.profileService.getQuestionsBySectionOrder(Number(sectionOrder), Number(userId));
      } else {
         data = await this.profileService.getProfileStructure(Number(userId));
      }

      res.status(200).json(new ApiResponse(200, data, "Questions fetched successfully"));
   });

   public getSections = asyncHandler(async (req: Request, res: Response) => {
      const { isPrimary } = req.query;
      const isPrimaryBool = isPrimary === "true" ? true : isPrimary === "false" ? false : undefined;
      const data = await this.profileService.getSections(isPrimaryBool);
      console.log("👉 data: ", data);
      res.status(200).json(new ApiResponse(200, data, "Sections fetched successfully"));
   });

   public getAnswers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const data = await this.profileService.getUserAnswers(Number(userId));
      res.status(200).json(new ApiResponse(200, data, "Answers fetched successfully"));
   });

   public saveAnswer = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { userId, questionId } = req.params;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const { answer } = req.body;

      if (!questionId || answer == null) {
         throw new ApiError(400, "You need to select an answer to proceed");
      }

      console.log(`👉 Saving answer`);

      const result = await this.profileService.saveAnswer(Number(userId), parseInt(questionId as string), answer);
      res.status(200).json(new ApiResponse(200, result, "Answer saved successfully"));
   });

   public completeProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const result = await this.profileService.completeProfile(Number(userId));
      res.status(200).json(new ApiResponse(200, result, "Profile completed successfully"));
   });

   public getCompletionStatus = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = req.params.userId;
      if (!userId) throw new ApiError(401, "Unauthorized");

      const result = await this.profileService.getProfileCompletionStatus(Number(userId));
      res.status(200).json(new ApiResponse(200, result, "Profile completion status fetched successfully"));
   });
}
