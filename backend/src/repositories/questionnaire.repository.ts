import prisma from "@/config/prisma";
import { Prisma, ProfileQuestion, ProfileSection } from "@prisma/client";
import { IQuestionnaireRepository } from "../interfaces/repositories/questionnaire.repository.interface";

export class QuestionnaireRepository implements IQuestionnaireRepository {
   // Sections
   async createSection(data: Prisma.ProfileSectionCreateInput): Promise<ProfileSection> {
      return prisma.profileSection.create({ data });
   }

   async getSectionByKey(key: string): Promise<ProfileSection | null> {
      return prisma.profileSection.findUnique({ where: { key } });
   }

   async getSectionById(id: number): Promise<(ProfileSection & { _count: { questions: number } }) | null> {
      return prisma.profileSection.findUnique({
         where: { id },
         include: { _count: { select: { questions: true } } },
      });
   }

   async getSectionsWithQuestions(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]> {
      return prisma.profileSection.findMany({
         orderBy: { orderNo: "asc" },
         include: {
            questions: {
               orderBy: { orderNo: "asc" },
            },
         },
      });
   }

   async updateSection(id: number, data: Prisma.ProfileSectionUpdateInput): Promise<ProfileSection> {
      return prisma.profileSection.update({
         where: { id },
         data,
      });
   }

   async deleteSection(id: number): Promise<ProfileSection> {
      return prisma.profileSection.delete({ where: { id } });
   }

   async reorderSections(orderedIds: number[]): Promise<ProfileSection[]> {
      const queries = orderedIds.map((id, index) =>
         prisma.profileSection.update({
            where: { id },
            data: { orderNo: index },
         })
      );
      return prisma.$transaction(queries);
   }

   // Questions
   async getQuestionById(id: number): Promise<ProfileQuestion | null> {
      return prisma.profileQuestion.findUnique({ where: { id } });
   }

   async getQuestionByIdWithAnswersCount(id: number): Promise<(ProfileQuestion & { _count: { answers: number } }) | null> {
      return prisma.profileQuestion.findUnique({
         where: { id },
         include: { _count: { select: { answers: true } } },
      });
   }

   async createQuestion(data: Prisma.ProfileQuestionUncheckedCreateInput): Promise<ProfileQuestion> {
      return prisma.profileQuestion.create({ data });
   }

   async updateQuestion(id: number, data: Prisma.ProfileQuestionUpdateInput): Promise<ProfileQuestion> {
      return prisma.profileQuestion.update({
         where: { id },
         data,
      });
   }

   async deleteQuestion(id: number): Promise<ProfileQuestion> {
      return prisma.profileQuestion.delete({ where: { id } });
   }

   async reorderQuestions(sectionId: number, orderedIds: number[]): Promise<ProfileQuestion[]> {
      const queries = orderedIds.map((id, index) =>
         prisma.profileQuestion.update({
            where: { id, sectionId },
            data: { orderNo: index },
         })
      );
      return prisma.$transaction(queries);
   }
}
