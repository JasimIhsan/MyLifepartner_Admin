import adminQuestionnaireService from "@/services/admin/admin.questionnaire.service";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

// ==========================================
// Sections
// ==========================================

export const createSection = asyncHandler(async (req: Request, res: Response) => {
   const { key, title, orderNo, isPrimary } = req.body;
   const section = await adminQuestionnaireService.createSection({ key, title, orderNo, isPrimary });
   res.status(201).json(new ApiResponse(201, section, "Section created successfully"));
});

export const getSections = asyncHandler(async (req: Request, res: Response) => {
   const sections = await adminQuestionnaireService.getSections();
   res.status(200).json(new ApiResponse(200, sections, "Sections retrieved successfully"));
});

export const updateSection = asyncHandler(async (req: Request, res: Response) => {
   const { id } = req.params;
   const { key, title, isPrimary } = req.body;
   const section = await adminQuestionnaireService.updateSection(parseInt(id as string), { key, title, isPrimary });
   res.status(200).json(new ApiResponse(200, section, "Section updated successfully"));
});

export const deleteSection = asyncHandler(async (req: Request, res: Response) => {
   const { id } = req.params;
   await adminQuestionnaireService.deleteSection(parseInt(id as string));
   res.status(200).json(new ApiResponse(200, null, "Section deleted successfully"));
});

export const reorderSections = asyncHandler(async (req: Request, res: Response) => {
   const { orderedIds } = req.body; // array of section IDs in the new order
   if (!Array.isArray(orderedIds)) {
      res.status(400).json(new ApiResponse(400, null, "orderedIds must be an array"));
      return;
   }
   await adminQuestionnaireService.reorderSections(orderedIds);
   res.status(200).json(new ApiResponse(200, null, "Sections reordered successfully"));
});

// ==========================================
// Questions
// ==========================================

export const createQuestion = asyncHandler(async (req: Request, res: Response) => {
   const { sectionId } = req.params;
   const data = req.body;
   const question = await adminQuestionnaireService.createQuestion(parseInt(sectionId as string), data);
   res.status(201).json(new ApiResponse(201, question, "Question created successfully"));
});

export const updateQuestion = asyncHandler(async (req: Request, res: Response) => {
   const { id } = req.params;
   const data = req.body;
   const question = await adminQuestionnaireService.updateQuestion(parseInt(id as string), data);
   res.status(200).json(new ApiResponse(200, question, "Question updated successfully"));
});

export const toggleQuestionActive = asyncHandler(async (req: Request, res: Response) => {
   const { id } = req.params;
   const question = await adminQuestionnaireService.toggleQuestionActive(parseInt(id as string));
   res.status(200).json(new ApiResponse(200, question, "Question active status toggled successfully"));
});

export const deleteQuestion = asyncHandler(async (req: Request, res: Response) => {
   const { id } = req.params;
   await adminQuestionnaireService.deleteQuestion(parseInt(id as string));
   res.status(200).json(new ApiResponse(200, null, "Question deleted successfully"));
});

export const reorderQuestions = asyncHandler(async (req: Request, res: Response) => {
   const { sectionId } = req.params;
   const { orderedIds } = req.body; // array of question IDs in the new order
   if (!Array.isArray(orderedIds)) {
      res.status(400).json(new ApiResponse(400, null, "orderedIds must be an array"));
      return;
   }
   await adminQuestionnaireService.reorderQuestions(parseInt(sectionId as string), orderedIds);
   res.status(200).json(new ApiResponse(200, null, "Questions reordered successfully"));
});
