import { ProfileService } from "@/services/profile.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

const profileService = new ProfileService();

export const getQuestions = asyncHandler(async (req: Request, res: Response) => {
   // @ts-ignore - Assuming auth middleware adds user to req
   const userId = req.params.userId;
   const { sectionOrder } = req.query;

   if (!userId) throw new ApiError(401, "Unauthorized");

   let data;
   if (sectionOrder) {
      data = await profileService.getQuestionsBySectionOrder(Number(sectionOrder), Number(userId));
   } else {
      data = await profileService.getProfileStructure(Number(userId));
   }

   res.status(200).json(new ApiResponse(200, data, "Questions fetched successfully"));
});

export const getSections = asyncHandler(async (req: Request, res: Response) => {
   const { isPrimary } = req.query;
   const isPrimaryBool = isPrimary === "true" ? true : isPrimary === "false" ? false : undefined;
   const data = await profileService.getSections(isPrimaryBool);
   console.log("👉 data: ", data);
   res.status(200).json(new ApiResponse(200, data, "Sections fetched successfully"));
});

export const getAnswers = asyncHandler(async (req: Request, res: Response) => {
   // @ts-ignore
   const userId = req.params.userId;
   if (!userId) throw new ApiError(401, "Unauthorized");

   const data = await profileService.getUserAnswers(Number(userId));
   res.status(200).json(new ApiResponse(200, data, "Answers fetched successfully"));
});

export const saveAnswer = asyncHandler(async (req: Request, res: Response) => {
   // @ts-ignore
   const { userId, questionId } = req.params;
   if (!userId) throw new ApiError(401, "Unauthorized");

   const { answer } = req.body;

   if (!questionId || answer == null) {
      throw new ApiError(400, "You need to select an answer to proceed");
   }

   console.log(`👉 Saving answer`);

   const result = await profileService.saveAnswer(Number(userId), parseInt(questionId as string), answer);
   res.status(200).json(new ApiResponse(200, result, "Answer saved successfully"));
});

export const completeProfile = asyncHandler(async (req: Request, res: Response) => {
   // @ts-ignore
   const userId = req.params.userId;
   if (!userId) throw new ApiError(401, "Unauthorized");

   const result = await profileService.completeProfile(Number(userId));
   res.status(200).json(new ApiResponse(200, result, "Profile completed successfully"));
});
