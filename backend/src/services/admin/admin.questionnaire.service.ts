import prisma from "@/config/prisma";
import { ApiError } from "@/utils/ApiError";
import { AnswerType, Prisma } from "@prisma/client";

class AdminQuestionnaireService {
   // ==========================================
   // Sections
   // ==========================================

   async createSection(data: { key: string; title: string; orderNo?: number; isPrimary?: boolean }) {
      const existing = await prisma.profileSection.findUnique({ where: { key: data.key } });
      if (existing) {
         throw new ApiError(409, `Section with key '${data.key}' already exists`);
      }
      return await prisma.profileSection.create({ data });
   }

   async getSections() {
      return await prisma.profileSection.findMany({
         orderBy: { orderNo: "asc" },
         include: {
            questions: {
               orderBy: { orderNo: "asc" },
            },
         },
      });
   }

   async updateSection(id: number, data: { key?: string; title?: string; isPrimary?: boolean }) {
      if (data.key) {
         const existing = await prisma.profileSection.findUnique({ where: { key: data.key } });
         if (existing && existing.id !== id) {
            throw new ApiError(409, `Section with key '${data.key}' already exists`);
         }
      }
      return await prisma.profileSection.update({
         where: { id },
         data,
      });
   }

   async deleteSection(id: number) {
      // Check if there are questions attached
      const section = await prisma.profileSection.findUnique({
         where: { id },
         include: { _count: { select: { questions: true } } },
      });

      if (!section) {
         throw new ApiError(404, "Section not found");
      }

      if (section._count.questions > 0) {
         throw new ApiError(400, "Cannot delete section because it contains questions. Delete them first.");
      }

      return await prisma.profileSection.delete({ where: { id } });
   }

   async reorderSections(orderedIds: number[]) {
      // orderedIds is an array of section ids [3, 1, 2] meant to be in order 0, 1, 2
      const queries = orderedIds.map((id, index) =>
         prisma.profileSection.update({
            where: { id },
            data: { orderNo: index },
         })
      );
      return await prisma.$transaction(queries);
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
      const section = await prisma.profileSection.findUnique({ where: { id: sectionId } });
      if (!section) {
         throw new ApiError(404, "Section not found");
      }

      return await prisma.profileQuestion.create({
         data: {
            ...data,
            sectionId,
            options: data.options ?? Prisma.JsonNull,
         },
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
      const question = await prisma.profileQuestion.findUnique({ where: { id } });
      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return await prisma.profileQuestion.update({
         where: { id },
         data: {
            ...data,
            options: data.options !== undefined ? data.options : undefined,
         },
      });
   }

   async toggleQuestionActive(id: number) {
      const question = await prisma.profileQuestion.findUnique({ where: { id } });
      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return await prisma.profileQuestion.update({
         where: { id },
         data: { isActive: !question.isActive },
      });
   }

   async deleteQuestion(id: number) {
      const question = await prisma.profileQuestion.findUnique({
         where: { id },
         include: { _count: { select: { answers: true } } },
      });

      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      // Instead of deleting if it has answers we could prevent it, or we allow it but cascade is needed.
      // Assuming Prisma schema doesn't have cascade on UserAnswer, we throw error if answers exist.
      if (question._count.answers > 0) {
         throw new ApiError(400, "Cannot delete question because it has associated user answers. Consider hiding it instead.");
      }

      return await prisma.profileQuestion.delete({ where: { id } });
   }

   async reorderQuestions(sectionId: number, orderedIds: number[]) {
      const queries = orderedIds.map((id, index) =>
         prisma.profileQuestion.update({
            where: { id, sectionId },
            data: { orderNo: index },
         })
      );
      return await prisma.$transaction(queries);
   }
}

export default new AdminQuestionnaireService();
