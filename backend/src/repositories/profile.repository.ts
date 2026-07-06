import prisma from "@/config/prisma";
import { CreatePartnerPreferenceDto, UpdateProfileDto } from "@/dtos/profile.input.dto";
import { DrinkingHabit, Gender, MaritalStatus, Prisma, Profile, ProfileStatus, SmokingHabit } from "@prisma/client";
import { IProfileRepository } from "../interfaces/repositories/profile.repository.interface";

export class ProfileRepository implements IProfileRepository {
   /**
    * Gets the profile structure with active questions.
    *
    * @returns Profile sections with active questions.
    */
   async getProfileStructure() {
      return prisma.profileSection.findMany({
         include: {
            questions: {
               where: {
                  isActive: true,
               },
               orderBy: {
                  orderNo: "asc",
               },
            },
         },
         orderBy: {
            orderNo: "asc",
         },
      });
   }

   /**
    * Gets profile sections.
    *
    * @param isPrimary - Optional primary section filter.
    * @returns Profile sections.
    */
   async getSections(isPrimary?: boolean) {
      return prisma.profileSection.findMany({
         where:
            isPrimary !== undefined
               ? {
                    isPrimary,
                 }
               : undefined,
         orderBy: {
            orderNo: "asc",
         },
      });
   }

   /**
    * Gets questions by section order with user answers.
    *
    * @param sectionOrder - Section order number.
    * @param userId - User ID.
    * @returns Questions with section and user answers.
    */
   async getQuestionsBySectionByOrder(sectionOrder: number, userId: number) {
      return prisma.profileQuestion.findMany({
         where: {
            section: {
               orderNo: sectionOrder,
            },
            isActive: true,
         },
         orderBy: {
            orderNo: "asc",
         },
         include: {
            section: true,
            answers: {
               where: {
                  profile: {
                     userId,
                  },
               },
            },
         },
      });
   }

   /**
    * Gets user answers.
    *
    * @param userId - User ID.
    * @returns User answers.
    */
   async getUserAnswers(userId: number) {
      return prisma.userAnswer.findMany({
         where: {
            profile: {
               userId,
            },
         },
      });
   }

   /**
    * Saves or updates a user answer.
    *
    * @param userId - User ID.
    * @param questionId - Question ID.
    * @param answer - User answer.
    * @param score - Optional answer score.
    * @returns Created or updated user answer.
    */
   async saveAnswer(userId: number, questionId: number, answer: Prisma.InputJsonValue, score?: number) {
      const profile = await this.findOrCreateProfile(userId);

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

   /**
    * Updates profile status.
    *
    * @param userId - User ID.
    * @param status - Profile status.
    * @returns Updated profile.
    */
   async updateProfileStatus(userId: number, status: ProfileStatus) {
      return prisma.profile.update({
         where: {
            userId,
         },
         data: {
            profileStatus: status,
         },
      });
   }

   /**
    * Gets required questions count.
    *
    * @param isPrimary - Optional primary section filter.
    * @returns Required questions count.
    */
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

   /**
    * Gets answered required questions count for a user.
    *
    * @param userId - User ID.
    * @param isPrimary - Optional primary section filter.
    * @returns Answered required questions count.
    */
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
            profile: {
               userId,
            },
         },
      });
   }

   /**
    * Updates basic profile details.
    *
    * @param userId - User ID.
    * @param data - Profile update data.
    * @returns Updated profile.
    */
   async updateBasicProfile(userId: number, data: UpdateProfileDto) {
      await this.findOrCreateProfile(userId);

      const updateData: Prisma.ProfileUpdateInput = {
         hasCompletedBasicDetails: true,
      };

      if (data.name !== undefined) updateData.name = data.name;
      if (data.dob !== undefined) updateData.dateOfBirth = typeof data.dob === "string" ? new Date(data.dob) : data.dob;
      if (data.gender !== undefined) updateData.gender = data.gender as Gender;
      if (data.motherTongue !== undefined) updateData.motherTongue = data.motherTongue;
      if (data.maritalStatus !== undefined) updateData.maritalStatus = data.maritalStatus as MaritalStatus;
      if (data.height !== undefined) updateData.heightCm = data.height;
      if (data.about !== undefined) updateData.bio = data.about;
      if (data.city !== undefined) updateData.city = data.city;
      if (data.state !== undefined) updateData.state = data.state;
      if (data.country !== undefined) updateData.country = data.country;
      if (data.education !== undefined) updateData.highestEducation = data.education;
      if (data.occupation !== undefined) updateData.occupation = data.occupation;
      if (data.smoke !== undefined) updateData.smokingHabit = data.smoke as SmokingHabit;
      if (data.drink !== undefined) updateData.drinkingHabit = data.drink as DrinkingHabit;

      return prisma.profile.update({
         where: {
            userId,
         },
         data: updateData,
      });
   }

   /**
    * Updates partner preference.
    *
    * @param userId - User ID.
    * @param data - Partner preference data.
    * @returns Created or updated partner preference.
    */
   async updatePartnerPreference(userId: number, data: CreatePartnerPreferenceDto) {
      await this.findOrCreateProfile(userId);

      const mappedData = {
         ageFrom: data.ageMin,
         ageTo: data.ageMax,
         heightFrom: data.heightMin,
         heightTo: data.heightMax,
         maritalStatus: data.maritalStatus ? [data.maritalStatus as MaritalStatus] : undefined,
         motherTongue: data.motherTongue ? [data.motherTongue] : undefined,
         highestEducation: data.education ? [data.education] : undefined,
         occupation: data.occupation ? [data.occupation] : undefined,
      };

      const partnerPreference = await prisma.partnerPreference.upsert({
         where: {
            userId,
         },
         update: mappedData,
         create: {
            ...mappedData,
            user: {
               connect: {
                  id: userId,
               },
            },
         },
      });

      await prisma.profile.update({
         where: {
            userId,
         },
         data: {
            hasCompletedPartnerPreference: true,
         },
      });

      return partnerPreference;
   }

   /**
    * Gets user images.
    *
    * @param userId - User ID.
    * @returns User images.
    */
   async getUserImages(userId: number) {
      return prisma.userImage.findMany({
         where: {
            profile: {
               userId,
            },
         },
         orderBy: {
            createdAt: "asc",
         },
      });
   }

   /**
    * Gets user image count.
    *
    * @param userId - User ID.
    * @returns User image count.
    */
   async getUserImagesCount(userId: number) {
      return prisma.userImage.count({
         where: {
            profile: {
               userId,
            },
         },
      });
   }

   /**
    * Gets a user image by ID.
    *
    * @param id - User image ID.
    * @returns User image with profile, or null if not found.
    */
   async getUserImageById(id: number) {
      return prisma.userImage.findUnique({
         where: {
            id,
         },
         include: {
            profile: true,
         },
      });
   }

   /**
    * Saves a user image.
    *
    * @param userId - User ID.
    * @param imageUrl - Image URL.
    * @param isPrimary - Whether the image is primary.
    * @returns Created user image.
    */
   async saveUserImage(userId: number, imageUrl: string, isPrimary: boolean = false) {
      const profile = await this.findOrCreateProfile(userId);

      return prisma.userImage.create({
         data: {
            profileId: profile.id,
            imageUrl,
            isPrimary,
         },
      });
   }

   /**
    * Deletes a user image.
    *
    * @param id - User image ID.
    * @returns Deleted user image.
    */
   async deleteUserImage(id: number) {
      return prisma.userImage.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Unsets primary images of a user.
    *
    * @param userId - User ID.
    * @returns Prisma batch update result.
    */
   async unsetPrimaryImages(userId: number) {
      return prisma.userImage.updateMany({
         where: {
            profile: {
               userId,
            },
            isPrimary: true,
         },
         data: {
            isPrimary: false,
         },
      });
   }

   /**
    * Sets an image as primary.
    *
    * @param id - User image ID.
    * @returns Updated user image.
    */
   async setImageAsPrimary(id: number) {
      return prisma.userImage.update({
         where: {
            id,
         },
         data: {
            isPrimary: true,
         },
      });
   }

   /**
    * Marks image upload as completed.
    *
    * @param userId - User ID.
    * @returns Updated profile.
    */
   async completeImageUpload(userId: number) {
      await this.findOrCreateProfile(userId);

      return prisma.profile.update({
         where: {
            userId,
         },
         data: {
            hasCompletedImageUpload: true,
         },
      });
   }

   /**
    * Saves user selfie images.
    *
    * @param userId - User ID.
    * @param frontUrl - Front selfie image URL.
    * @param leftUrl - Left selfie image URL.
    * @param rightUrl - Right selfie image URL.
    * @param latitude - Optional latitude.
    * @param longitude - Optional longitude.
    * @returns Updated profile and old selfie URLs.
    */
   async saveSelfie(userId: number, frontUrl: string, leftUrl: string, rightUrl: string, latitude?: number, longitude?: number) {
      const profile = await this.findOrCreateProfile(userId);

      const oldSelfieUrls = {
         front: profile.selfieUrl,
         left: profile.leftSelfieUrl,
         right: profile.rightSelfieUrl,
      };

      const updateData: Prisma.ProfileUpdateInput = {
         selfieUrl: frontUrl,
         leftSelfieUrl: leftUrl,
         rightSelfieUrl: rightUrl,
         selfieStatus: "PENDING",
         ...(latitude !== undefined && {
            lastLocationLat: latitude,
         }),
         ...(longitude !== undefined && {
            lastLocationLng: longitude,
         }),
      };

      const updatedProfile = await prisma.profile.update({
         where: {
            userId,
         },
         data: updateData,
      });

      return {
         user: updatedProfile,
         oldSelfieUrls,
      };
   }

   /**
    * Finds or creates a profile.
    *
    * @param userId - User ID.
    * @returns Existing or created profile.
    */
   private async findOrCreateProfile(userId: number): Promise<Profile> {
      return prisma.profile.upsert({
         where: {
            userId,
         },
         update: {},
         create: {
            userId,
         },
      });
   }
}
