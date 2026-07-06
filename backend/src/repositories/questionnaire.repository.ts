import prisma from "@/config/prisma";
import { Prisma, ProfileQuestion, ProfileSection } from "@prisma/client";
import { IQuestionnaireRepository } from "../interfaces/repositories/questionnaire.repository.interface";

export class QuestionnaireRepository implements IQuestionnaireRepository {
   /**
    * Creates a profile section.
    *
    * @param data - Profile section creation data.
    * @returns Created profile section.
    */
   async createSection(data: Prisma.ProfileSectionCreateInput): Promise<ProfileSection> {
      return prisma.profileSection.create({
         data,
      });
   }

   /**
    * Finds a profile section by key.
    *
    * @param key - Profile section key.
    * @returns Profile section, or null if not found.
    */
   async getSectionByKey(key: string): Promise<ProfileSection | null> {
      return prisma.profileSection.findUnique({
         where: {
            key,
         },
      });
   }

   /**
    * Finds a profile section by ID with questions count.
    *
    * @param id - Profile section ID.
    * @returns Profile section with questions count, or null if not found.
    */
   async getSectionById(id: number): Promise<(ProfileSection & { _count: { questions: number } }) | null> {
      return prisma.profileSection.findUnique({
         where: {
            id,
         },
         include: {
            _count: {
               select: {
                  questions: true,
               },
            },
         },
      });
   }

   /**
    * Gets all profile sections with questions.
    *
    * @returns List of profile sections with questions.
    */
   async getSectionsWithQuestions(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]> {
      return prisma.profileSection.findMany({
         orderBy: {
            orderNo: "asc",
         },
         include: {
            questions: {
               orderBy: {
                  orderNo: "asc",
               },
            },
         },
      });
   }

   /**
    * Updates a profile section.
    *
    * @param id - Profile section ID.
    * @param data - Profile section update data.
    * @returns Updated profile section.
    */
   async updateSection(id: number, data: Prisma.ProfileSectionUpdateInput): Promise<ProfileSection> {
      return prisma.profileSection.update({
         where: {
            id,
         },
         data,
      });
   }

   /**
    * Deletes a profile section.
    *
    * @param id - Profile section ID.
    * @returns Deleted profile section.
    */
   async deleteSection(id: number): Promise<ProfileSection> {
      return prisma.profileSection.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Reorders profile sections.
    *
    * @param orderedIds - Profile section IDs in the new order.
    * @returns Updated profile sections.
    */
   async reorderSections(orderedIds: number[]): Promise<ProfileSection[]> {
      const queries = orderedIds.map((id, index) =>
         prisma.profileSection.update({
            where: {
               id,
            },
            data: {
               orderNo: index,
            },
         })
      );

      return prisma.$transaction(queries);
   }

   /**
    * Finds a profile question by ID.
    *
    * @param id - Profile question ID.
    * @returns Profile question, or null if not found.
    */
   async getQuestionById(id: number): Promise<ProfileQuestion | null> {
      return prisma.profileQuestion.findUnique({
         where: {
            id,
         },
      });
   }

   /**
    * Finds a profile question by ID with answers count.
    *
    * @param id - Profile question ID.
    * @returns Profile question with answers count, or null if not found.
    */
   async getQuestionByIdWithAnswersCount(id: number): Promise<(ProfileQuestion & { _count: { answers: number } }) | null> {
      return prisma.profileQuestion.findUnique({
         where: {
            id,
         },
         include: {
            _count: {
               select: {
                  answers: true,
               },
            },
         },
      });
   }

   /**
    * Creates a profile question.
    *
    * @param data - Profile question creation data.
    * @returns Created profile question.
    */
   async createQuestion(data: Prisma.ProfileQuestionUncheckedCreateInput): Promise<ProfileQuestion> {
      return prisma.profileQuestion.create({
         data,
      });
   }

   /**
    * Updates a profile question.
    *
    * @param id - Profile question ID.
    * @param data - Profile question update data.
    * @returns Updated profile question.
    */
   async updateQuestion(id: number, data: Prisma.ProfileQuestionUpdateInput): Promise<ProfileQuestion> {
      return prisma.profileQuestion.update({
         where: {
            id,
         },
         data,
      });
   }

   /**
    * Deletes a profile question.
    *
    * @param id - Profile question ID.
    * @returns Deleted profile question.
    */
   async deleteQuestion(id: number): Promise<ProfileQuestion> {
      return prisma.profileQuestion.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Reorders profile questions inside a section.
    *
    * @param sectionId - Profile section ID.
    * @param orderedIds - Profile question IDs in the new order.
    * @returns Updated profile questions.
    */
   async reorderQuestions(sectionId: number, orderedIds: number[]): Promise<ProfileQuestion[]> {
      const queries = orderedIds.map((id, index) =>
         prisma.profileQuestion.update({
            where: {
               id,
               sectionId,
            },
            data: {
               orderNo: index,
            },
         })
      );

      return prisma.$transaction(queries);
   }
}
