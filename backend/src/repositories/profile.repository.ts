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

   async getTotalQuestionsCount() {
      // Count all active required questions
      return prisma.profileQuestion.count({
         where: {
            isActive: true,
            isRequired: true, // Only optional questions don't block completion?
            // Wait, usually completion means all required are done.
         },
      });
   }

   async getRequiredQuestionsCount() {
      return prisma.profileQuestion.count({
         where: {
            isActive: true,
            isRequired: true,
         },
      });
   }

   async getUserAnsweredCount(userId: number) {
      return prisma.userAnswer.count({
         where: {
            userId,
            question: {
               isRequired: true,
               isActive: true,
            },
         },
      });
   }
}
