import prisma from "@/config/prisma";
import { ProfileStatus } from "@prisma/client";
import { IProfileRepository } from "../interfaces/repositories/profile.repository.interface";

export class ProfileRepository implements IProfileRepository {
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
                  profile: { userId: userId },
               },
            },
         },
      });
   }

   async getUserAnswers(userId: number) {
      return prisma.userAnswer.findMany({
         where: { profile: { userId } },
      });
   }

   async saveAnswer(userId: number, questionId: number, answer: import("@prisma/client").Prisma.InputJsonValue, score?: number) {
      let profile = await prisma.profile.findUnique({ where: { userId } });
      if (!profile) profile = await prisma.profile.create({ data: { userId } });

      return prisma.userAnswer.upsert({
         where: {
            profileId_questionId: {
               profileId: profile.id,
               questionId,
            },
         },
         update: {
            answer,
            score,
         },
         create: {
            profileId: profile.id,
            questionId,
            answer,
            score,
         },
      });
   }

   async updateProfileStatus(userId: number, status: ProfileStatus) {
      return prisma.profile.update({
         where: { userId },
         data: { profileStatus: status },
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
            question: {
               isRequired: true,
               isActive: true,
               ...(isPrimary !== undefined && {
                  section: {
                     isPrimary,
                  },
               }),
            },
            profile: { userId },
         },
      });
   }

   async updateBasicProfile(userId: number, data: import("@prisma/client").Prisma.ProfileUpdateInput) {
      let profile = await prisma.profile.findUnique({ where: { userId } });
      if (!profile) profile = await prisma.profile.create({ data: { userId } });

      return prisma.profile.update({
         where: { userId },
         data,
      });
   }

   async updatePartnerPreference(userId: number, data: Omit<import("@prisma/client").Prisma.PartnerPreferenceCreateInput, "user">) {
      return prisma.partnerPreference.upsert({
         where: { userId },
         update: data as any,
         create: {
            ...data,
            user: { connect: { id: userId } },
         } as any,
      });
   }

   async getUserImages(userId: number) {
      return prisma.userImage.findMany({
         where: { profile: { userId } },
         orderBy: { createdAt: "asc" },
      });
   }

   async getUserImagesCount(userId: number) {
      return prisma.userImage.count({
         where: { profile: { userId } },
      });
   }

   async getUserImageById(id: number) {
      return prisma.userImage.findUnique({
         where: { id },
         include: { profile: true },
      });
   }

   async saveUserImage(userId: number, imageUrl: string, isPrimary: boolean = false) {
      let profile = await prisma.profile.findUnique({ where: { userId } });
      if (!profile) profile = await prisma.profile.create({ data: { userId } });

      return prisma.userImage.create({
         data: {
            profileId: profile.id,
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
         where: { profile: { userId }, isPrimary: true },
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
      let profile = await prisma.profile.findUnique({ where: { userId } });
      if (!profile) profile = await prisma.profile.create({ data: { userId } });

      return prisma.profile.update({
         where: { userId },
         data: { hasCompletedImageUpload: true },
      });
   }

   async saveSelfie(userId: number, selfieUrl: string) {
      let profile = await prisma.profile.findUnique({ where: { userId } });
      if (!profile) profile = await prisma.profile.create({ data: { userId } });

      const oldSelfieUrl = profile.selfieUrl;

      const updatedProfile = await prisma.profile.update({
         where: { userId },
         data: {
            selfieUrl,
            selfieStatus: "PENDING",
         },
      });

      return { user: updatedProfile, oldSelfieUrl };
   }
}
