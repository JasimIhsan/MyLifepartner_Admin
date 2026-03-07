import { IAdminQuestionnaireService } from "@/interfaces/services/admin.questionnaire.service.interface";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

export class AdminQuestionnaireController {
   constructor(private adminQuestionnaireService: IAdminQuestionnaireService) {}

   // ==========================================
   // Sections
   // ==========================================

   createSection = asyncHandler(async (req: Request, res: Response) => {
      const { key, title, orderNo, isPrimary } = req.body;
      const section = await this.adminQuestionnaireService.createSection({ key, title, orderNo, isPrimary });
      res.status(201).json(new ApiResponse(201, section, "Section created successfully"));
   });

   getSections = asyncHandler(async (req: Request, res: Response) => {
      const sections = await this.adminQuestionnaireService.getSections();
      res.status(200).json(new ApiResponse(200, sections, "Sections retrieved successfully"));
   });

   updateSection = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      const { key, title, isPrimary } = req.body;
      const section = await this.adminQuestionnaireService.updateSection(parseInt(id as string), { key, title, isPrimary });
      res.status(200).json(new ApiResponse(200, section, "Section updated successfully"));
   });

   deleteSection = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      await this.adminQuestionnaireService.deleteSection(parseInt(id as string));
      res.status(200).json(new ApiResponse(200, null, "Section deleted successfully"));
   });

   reorderSections = asyncHandler(async (req: Request, res: Response) => {
      const { orderedIds } = req.body;
      if (!Array.isArray(orderedIds)) {
         res.status(400).json(new ApiResponse(400, null, "orderedIds must be an array"));
         return;
      }
      await this.adminQuestionnaireService.reorderSections(orderedIds);
      res.status(200).json(new ApiResponse(200, null, "Sections reordered successfully"));
   });

   // ==========================================
   // Questions
   // ==========================================

   createQuestion = asyncHandler(async (req: Request, res: Response) => {
      const { sectionId } = req.params;
      const data = req.body;
      const question = await this.adminQuestionnaireService.createQuestion(parseInt(sectionId as string), data);
      res.status(201).json(new ApiResponse(201, question, "Question created successfully"));
   });

   updateQuestion = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      const data = req.body;
      const question = await this.adminQuestionnaireService.updateQuestion(parseInt(id as string), data);
      res.status(200).json(new ApiResponse(200, question, "Question updated successfully"));
   });

   toggleQuestionActive = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      const question = await this.adminQuestionnaireService.toggleQuestionActive(parseInt(id as string));
      res.status(200).json(new ApiResponse(200, question, "Question active status toggled successfully"));
   });

   deleteQuestion = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      await this.adminQuestionnaireService.deleteQuestion(parseInt(id as string));
      res.status(200).json(new ApiResponse(200, null, "Question deleted successfully"));
   });

   reorderQuestions = asyncHandler(async (req: Request, res: Response) => {
      const { sectionId } = req.params;
      const { orderedIds } = req.body;
      if (!Array.isArray(orderedIds)) {
         res.status(400).json(new ApiResponse(400, null, "orderedIds must be an array"));
         return;
      }
      await this.adminQuestionnaireService.reorderQuestions(parseInt(sectionId as string), orderedIds);
      res.status(200).json(new ApiResponse(200, null, "Questions reordered successfully"));
   });
}
