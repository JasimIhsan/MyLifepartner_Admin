import prisma from "@/config/prisma";

export class ProfileRepository {
   async getProfileStructure() {
      return prisma.profileSection.findMany({
         include: {
            questions: {
               where: { isActive: true },
               orderBy: { orderNo: "asc" },
            },
         },
         orderBy: { orderNo: "asc" },
      });
   }

   async getSections(isPrimary?: boolean) {
      if (isPrimary !== undefined) {
         return prisma.profileSection.findMany({
            where: { isPrimary },
            orderBy: { orderNo: "asc" },
         });
      }
      return prisma.profileSection.findMany({
         orderBy: { orderNo: "asc" },
      });
   }

   async getQuestionsBySectionByOrder(sectionOrder: number, userId: number) {
      return prisma.profileQuestion.findMany({
         where: {
            section: {
               orderNo: sectionOrder,
            },
            isActive: true,
         },
         orderBy: { orderNo: "asc" },
         include: {
            section: true,
            answers: {
               where: {
                  userId: userId,
               },
               select: {
                  answer: true,
                  score: true,
               },
            },
         },
      });
   }

   async getUserAnswers(userId: number) {
      return prisma.userAnswer.findMany({
         where: { userId },
      });
   }

   async saveAnswer(userId: number, questionId: number, answer: any, score?: number) {
      return prisma.userAnswer.upsert({
         where: {
            userId_questionId: {
               userId,
               questionId,
            },
         },
         update: {
            answer,
            score,
         },
         create: {
            userId,
            questionId,
            answer,
            score,
         },
      });
   }

   async setProfileCompleted(userId: number) {
      return prisma.user.update({
         where: { id: userId },
         data: { isProfileCompleted: true },
      });
   }

   async getRequiredPrimaryQuestionsCount() {
      return prisma.profileQuestion.count({
         where: {
            isActive: true,
            isRequired: true,
            section: {
               isPrimary: true,
            },
         },
      });
   }

   async getUserPrimaryAnsweredCount(userId: number) {
      return prisma.userAnswer.count({
         where: {
            userId,
            question: {
               isRequired: true,
               isActive: true,
               section: {
                  isPrimary: true,
               },
            },
         },
      });
   }
}
