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

   async getRequiredQuestionsCount(isPrimary?: boolean) {
      return prisma.profileQuestion.count({
         where: {
            isActive: true,
            isRequired: true,
            ...(isPrimary !== undefined && {
               section: {
                  isPrimary,
               },
            }),
         },
      });
   }

   async getUserAnsweredCount(userId: number, isPrimary?: boolean) {
      return prisma.userAnswer.count({
         where: {
            userId,
            question: {
               isRequired: true,
               isActive: true,
               ...(isPrimary !== undefined && {
                  section: {
                     isPrimary,
                  },
               }),
            },
         },
      });
   }

   async getUserImages(userId: number) {
      return prisma.userImage.findMany({
         where: { userId },
         orderBy: { createdAt: "asc" },
      });
   }

   async getUserImagesCount(userId: number) {
      return prisma.userImage.count({
         where: { userId },
      });
   }

   async getUserImageById(id: number) {
      return prisma.userImage.findUnique({
         where: { id },
      });
   }

   async saveUserImage(userId: number, imageUrl: string, isPrimary: boolean = false) {
      return prisma.userImage.create({
         data: {
            userId,
            imageUrl,
            isPrimary,
         },
      });
   }

   async deleteUserImage(id: number) {
      return prisma.userImage.delete({
         where: { id },
      });
   }

   async unsetPrimaryImages(userId: number) {
      return prisma.userImage.updateMany({
         where: { userId, isPrimary: true },
         data: { isPrimary: false },
      });
   }

   async setImageAsPrimary(id: number) {
      return prisma.userImage.update({
         where: { id },
         data: { isPrimary: true },
      });
   }

   async completeImageUpload(userId: number) {
      return prisma.user.update({
         where: { id: userId },
         data: { hasCompletedImageUpload: true },
      });
   }

   async saveSelfie(userId: number, selfieUrl: string) {
      const user = await prisma.user.findUnique({ where: { id: userId } });
      const oldSelfieUrl = user?.selfieUrl;

      const updatedUser = await prisma.user.update({
         where: { id: userId },
         data: {
            selfieUrl,
            selfieStatus: "PENDING",
         },
      });

      return { user: updatedUser, oldSelfieUrl };
   }
}
