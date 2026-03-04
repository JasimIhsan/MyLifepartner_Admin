import { ApiError } from "@/utils/ApiError";
import { AnswerType, Prisma } from "@prisma/client";
import { IQuestionnaireRepository } from "../../interfaces/repositories/questionnaire.repository.interface";
import { IAdminQuestionnaireService } from "../../interfaces/services/admin.questionnaire.service.interface";

export class AdminQuestionnaireService implements IAdminQuestionnaireService {
   constructor(private questionnaireRepository: IQuestionnaireRepository) {}

   // ==========================================
   // Sections
   // ==========================================

   async createSection(data: { key: string; title: string; orderNo?: number; isPrimary?: boolean }) {
      const existing = await this.questionnaireRepository.getSectionByKey(data.key);
      if (existing) {
         throw new ApiError(409, `Section with key '${data.key}' already exists`);
      }
      return await this.questionnaireRepository.createSection(data);
   }

   async getSections() {
      return await this.questionnaireRepository.getSectionsWithQuestions();
   }

   async updateSection(id: number, data: { key?: string; title?: string; isPrimary?: boolean }) {
      if (data.key) {
         const existing = await this.questionnaireRepository.getSectionByKey(data.key);
         if (existing && existing.id !== id) {
            throw new ApiError(409, `Section with key '${data.key}' already exists`);
         }
      }
      return await this.questionnaireRepository.updateSection(id, data);
   }

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

   async createQuestion(
      sectionId: number,
      data: {
         question: string;
         answerType: AnswerType;
         options?: Prisma.InputJsonValue;
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
         options: data.options ?? Prisma.JsonNull,
      });
   }

   async updateQuestion(
      id: number,
      data: {
         question?: string;
         answerType?: AnswerType;
         options?: Prisma.InputJsonValue;
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
         options: data.options !== undefined ? data.options : undefined,
      });
   }

   async toggleQuestionActive(id: number) {
      const question = await this.questionnaireRepository.getQuestionById(id);
      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return await this.questionnaireRepository.updateQuestion(id, { isActive: !question.isActive });
   }

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
