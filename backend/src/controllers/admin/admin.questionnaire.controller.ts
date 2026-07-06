import { IAdminQuestionnaireService } from "@/interfaces/services/admin.questionnaire.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class AdminQuestionnaireController {
   constructor(private readonly adminQuestionnaireService: IAdminQuestionnaireService) {}

   /**
    * @route POST /api/v1/admin/questionnaires/sections
    * @purpose Creates a new questionnaire section.
    */
   public createSection = asyncHandler(async (req: Request, res: Response) => {
      const { key, title, orderNo, isPrimary } = req.body;

      const section = await this.adminQuestionnaireService.createSection({
         key,
         title,
         orderNo,
         isPrimary,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, section, "Section created successfully"));
   });

   /**
    * @route GET /api/v1/admin/questionnaires/sections
    * @purpose Fetches all questionnaire sections.
    */
   public getSections = asyncHandler(async (_req: Request, res: Response) => {
      const sections = await this.adminQuestionnaireService.getSections();

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, sections, "Sections retrieved successfully"));
   });

   /**
    * @route PUT /api/v1/admin/questionnaires/sections/:id
    * @purpose Updates a questionnaire section by ID.
    */
   public updateSection = asyncHandler(async (req: Request, res: Response) => {
      const sectionId = Number(req.params.id);

      if (!Number.isInteger(sectionId) || sectionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid section ID");
      }

      const { key, title, isPrimary } = req.body;

      const section = await this.adminQuestionnaireService.updateSection(sectionId, {
         key,
         title,
         isPrimary,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, section, "Section updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/questionnaires/sections/:id
    * @purpose Deletes a questionnaire section by ID.
    */
   public deleteSection = asyncHandler(async (req: Request, res: Response) => {
      const sectionId = Number(req.params.id);

      if (!Number.isInteger(sectionId) || sectionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid section ID");
      }

      await this.adminQuestionnaireService.deleteSection(sectionId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Section deleted successfully"));
   });

   /**
    * @route PUT /api/v1/admin/questionnaires/sections/reorder
    * @purpose Reorders questionnaire sections.
    */
   public reorderSections = asyncHandler(async (req: Request, res: Response) => {
      const { orderedIds } = req.body;

      if (!this.isValidOrderedIds(orderedIds)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "orderedIds must be an array of valid IDs");
      }

      await this.adminQuestionnaireService.reorderSections(orderedIds);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Sections reordered successfully"));
   });

   /**
    * @route POST /api/v1/admin/questionnaires/sections/:sectionId/questions
    * @purpose Creates a new question under a section.
    */
   public createQuestion = asyncHandler(async (req: Request, res: Response) => {
      const sectionId = Number(req.params.sectionId);

      if (!Number.isInteger(sectionId) || sectionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid section ID");
      }

      const question = await this.adminQuestionnaireService.createQuestion(sectionId, req.body);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, question, "Question created successfully"));
   });

   /**
    * @route PUT /api/v1/admin/questionnaires/questions/:id
    * @purpose Updates a question by ID.
    */
   public updateQuestion = asyncHandler(async (req: Request, res: Response) => {
      const questionId = Number(req.params.id);

      if (!Number.isInteger(questionId) || questionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid question ID");
      }

      const question = await this.adminQuestionnaireService.updateQuestion(questionId, req.body);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, question, "Question updated successfully"));
   });

   /**
    * @route PATCH /api/v1/admin/questionnaires/questions/:id/toggle-active
    * @purpose Toggles active status of a question.
    */
   public toggleQuestionActive = asyncHandler(async (req: Request, res: Response) => {
      const questionId = Number(req.params.id);

      if (!Number.isInteger(questionId) || questionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid question ID");
      }

      const question = await this.adminQuestionnaireService.toggleQuestionActive(questionId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, question, "Question active status toggled successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/questionnaires/questions/:id
    * @purpose Deletes a question by ID.
    */
   public deleteQuestion = asyncHandler(async (req: Request, res: Response) => {
      const questionId = Number(req.params.id);

      if (!Number.isInteger(questionId) || questionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid question ID");
      }

      await this.adminQuestionnaireService.deleteQuestion(questionId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Question deleted successfully"));
   });

   /**
    * @route PUT /api/v1/admin/questionnaires/sections/:sectionId/questions/reorder
    * @purpose Reorders questions inside a section.
    */
   public reorderQuestions = asyncHandler(async (req: Request, res: Response) => {
      const sectionId = Number(req.params.sectionId);
      const { orderedIds } = req.body;

      if (!Number.isInteger(sectionId) || sectionId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid section ID");
      }

      if (!this.isValidOrderedIds(orderedIds)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "orderedIds must be an array of valid IDs");
      }

      await this.adminQuestionnaireService.reorderQuestions(sectionId, orderedIds);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Questions reordered successfully"));
   });

   /**
    * Checks whether ordered IDs are valid.
    */
   private isValidOrderedIds(value: unknown): value is number[] {
      return Array.isArray(value) && value.length > 0 && value.every((id) => Number.isInteger(id) && id > 0);
   }
}
