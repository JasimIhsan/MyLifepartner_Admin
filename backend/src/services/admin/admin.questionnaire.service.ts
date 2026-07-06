import { ApiError } from "@/utils/ApiError";
import { AnswerType } from "@prisma/client";
import { IQuestionnaireRepository } from "../../interfaces/repositories/questionnaire.repository.interface";
import { IAdminQuestionnaireService } from "../../interfaces/services/admin.questionnaire.service.interface";

export class AdminQuestionnaireService implements IAdminQuestionnaireService {
   constructor(private questionnaireRepository: IQuestionnaireRepository) {}

   // ==========================================
   // Sections
   // ==========================================

   /**
    * Creates a new questionnaire section
    * @param data - The section data including key and title
    * @returns The created section
    * @throws ApiError if section key already exists
    */
   async createSection(data: { key: string; title: string; orderNo?: number; isPrimary?: boolean }) {
      const existing = await this.questionnaireRepository.getSectionByKey(data.key);
      if (existing) {
         throw new ApiError(409, `Section with key '${data.key}' already exists`);
      }
      return await this.questionnaireRepository.createSection(data);
   }

   /**
    * Retrieves all questionnaire sections with their associated questions
    * @returns Array of sections with questions
    */
   async getSections() {
      return await this.questionnaireRepository.getSectionsWithQuestions();
   }

   /**
    * Updates an existing questionnaire section
    * @param id - The ID of the section to update
    * @param data - The fields to update
    * @returns The updated section
    * @throws ApiError if the new key already exists on another section
    */
   async updateSection(id: number, data: { key?: string; title?: string; isPrimary?: boolean }) {
      if (data.key) {
         const existing = await this.questionnaireRepository.getSectionByKey(data.key);
         if (existing && existing.id !== id) {
            throw new ApiError(409, `Section with key '${data.key}' already exists`);
         }
      }
      return await this.questionnaireRepository.updateSection(id, data);
   }

   /**
    * Deletes a questionnaire section
    * @param id - The ID of the section to delete
    * @returns The deleted section
    * @throws ApiError if the section is not found or if it still contains questions
    */
   async deleteSection(id: number) {
      // Check if there are questions attached
      const section = await this.questionnaireRepository.getSectionById(id);

      if (!section) {
         throw new ApiError(404, "Section not found");
      }

      if (section._count.questions > 0) {
         throw new ApiError(400, "Cannot delete section because it contains questions. Delete them first.");
      }

      return await this.questionnaireRepository.deleteSection(id);
   }

   async reorderSections(orderedIds: number[]) {
      return await this.questionnaireRepository.reorderSections(orderedIds);
   }

   // ==========================================
   // Questions
   // ==========================================

   /**
    * Creates a new question in a specific section
    * @param sectionId - The ID of the section
    * @param data - The question details
    * @returns The created question
    * @throws ApiError if the section is not found
    */
   async createQuestion(
      sectionId: number,
      data: {
         question: string;
         answerType: AnswerType;
         options?: unknown;
         minWords?: number;
         weight?: number;
         isRequired?: boolean;
         orderNo?: number;
         isActive?: boolean;
      }
   ) {
      const section = await this.questionnaireRepository.getSectionById(sectionId);
      if (!section) {
         throw new ApiError(404, "Section not found");
      }

      return await this.questionnaireRepository.createQuestion({
         ...data,
         sectionId,
         options: data.options !== undefined ? (data.options as import("@prisma/client").Prisma.InputJsonValue) : undefined,
      });
   }

   /**
    * Updates an existing question
    * @param id - The ID of the question to update
    * @param data - The fields to update
    * @returns The updated question
    * @throws ApiError if the question is not found
    */
   async updateQuestion(
      id: number,
      data: {
         question?: string;
         answerType?: AnswerType;
         options?: unknown;
         minWords?: number;
         weight?: number;
         isRequired?: boolean;
      }
   ) {
      const question = await this.questionnaireRepository.getQuestionById(id);
      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return await this.questionnaireRepository.updateQuestion(id, {
         ...data,
         options: data.options !== undefined ? (data.options as import("@prisma/client").Prisma.InputJsonValue) : undefined,
      });
   }

   /**
    * Toggles the active status of a question
    * @param id - The ID of the question
    * @returns The updated question
    * @throws ApiError if the question is not found
    */
   async toggleQuestionActive(id: number) {
      const question = await this.questionnaireRepository.getQuestionById(id);
      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return await this.questionnaireRepository.updateQuestion(id, { isActive: !question.isActive });
   }

   /**
    * Deletes a question
    * @param id - The ID of the question to delete
    * @returns The deleted question
    * @throws ApiError if the question is not found or has associated user answers
    */
   async deleteQuestion(id: number) {
      const question = await this.questionnaireRepository.getQuestionByIdWithAnswersCount(id);

      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      if (question._count.answers > 0) {
         throw new ApiError(400, "Cannot delete question because it has associated user answers. Consider hiding it instead.");
      }

      return await this.questionnaireRepository.deleteQuestion(id);
   }

   async reorderQuestions(sectionId: number, orderedIds: number[]) {
      return await this.questionnaireRepository.reorderQuestions(sectionId, orderedIds);
   }
}
