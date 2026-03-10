import prisma from "@/config/prisma";
import { SwipeAction } from "@prisma/client";
import { CandidateProfile, IMatchRepository, SwipedProfile, UserAnswerData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";

export class MatchRepository implements IMatchRepository {
   async getUserPreference(userId: number): Promise<UserPreferenceData | null> {
      const pref = await prisma.partnerPreference.findUnique({ where: { userId } });
      if (!pref) return null;
      return {
         ageFrom: pref.ageFrom,
         ageTo: pref.ageTo,
         heightFrom: pref.heightFrom,
         heightTo: pref.heightTo,
         religion: pref.religion,
         motherTongue: pref.motherTongue,
         highestEducation: pref.highestEducation,
         occupation: pref.occupation,
         annualIncomeFrom: pref.annualIncomeFrom,
         annualIncomeTo: pref.annualIncomeTo,
      };
   }

   async getUserAnswers(userId: number): Promise<UserAnswerData[]> {
      const answers = await prisma.userAnswer.findMany({
         where: { profile: { userId } },
         select: { questionId: true, answer: true, score: true },
      });
      return answers;
   }

   async getSwipedProfileIds(userId: number): Promise<SwipedProfile[]> {
      const swipes = await prisma.profileSwipe.findMany({
         where: { userId },
         select: { targetProfileId: true, action: true },
      });
      return swipes;
   }

   async getCandidateProfiles(currentUserId: number, excludedProfileIds: number[]): Promise<CandidateProfile[]> {
      const currentUser = await prisma.user.findUnique({ where: { id: currentUserId }, include: { profile: true } });
      const currentGender = currentUser?.profile?.gender;

      // Target profiles should be of opposite gender (or OTHER)
      const targetGender = currentGender === "MALE" ? { in: ["FEMALE", "OTHER"] } : currentGender === "FEMALE" ? { in: ["MALE", "OTHER"] } : undefined;

      const profiles = await prisma.profile.findMany({
         where: {
            profileStatus: "COMPLETED",
            user: {
               isBlocked: false,
               isDeleted: false,
               id: { not: currentUserId },
            },
            ...(targetGender && { gender: { in: targetGender.in as ("MALE" | "FEMALE" | "OTHER")[] } }),
            id: { notIn: excludedProfileIds },
         },
         include: {
            images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
            answers: { select: { questionId: true, answer: true, score: true } },
         },
      });

      return profiles.map((p) => ({
         id: p.id,
         userId: p.userId,
         name: p.name,
         dateOfBirth: p.dateOfBirth,
         heightCm: p.heightCm,
         maritalStatus: p.maritalStatus,
         city: p.city,
         state: p.state,
         country: p.country,
         religion: p.religion,
         motherTongue: p.motherTongue,
         highestEducation: p.highestEducation,
         occupation: p.occupation,
         annualIncome: p.annualIncome,
         bio: p.bio,
         gender: p.gender,
         images: p.images.map((img) => ({ imageUrl: img.imageUrl, isPrimary: img.isPrimary })),
         answers: p.answers,
      }));
   }

   async recordSwipe(userId: number, targetProfileId: number, action: SwipeAction): Promise<void> {
      const existing = await prisma.profileSwipe.findFirst({ where: { userId, targetProfileId } });
      if (existing) {
         await prisma.profileSwipe.update({ where: { id: existing.id }, data: { action } });
      } else {
         await prisma.profileSwipe.create({ data: { userId, targetProfileId, action } });
      }
   }
   async getProfileById(profileId: number): Promise<CandidateProfile | null> {
      const p = await prisma.profile.findUnique({
         where: { id: profileId },
         include: {
            images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
            answers: { select: { questionId: true, answer: true, score: true } },
         },
      });
      if (!p) return null;
      return {
         id: p.id,
         userId: p.userId,
         name: p.name,
         dateOfBirth: p.dateOfBirth,
         heightCm: p.heightCm,
         maritalStatus: p.maritalStatus,
         city: p.city,
         state: p.state,
         country: p.country,
         religion: p.religion,
         motherTongue: p.motherTongue,
         highestEducation: p.highestEducation,
         occupation: p.occupation,
         annualIncome: p.annualIncome,
         bio: p.bio,
         gender: p.gender,
         images: p.images.map((img) => ({ imageUrl: img.imageUrl, isPrimary: img.isPrimary })),
         answers: p.answers,
      };
   }
}
