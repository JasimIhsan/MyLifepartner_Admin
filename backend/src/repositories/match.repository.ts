import prisma from "@/config/prisma";
import { SwipeAction } from "@prisma/client";
import { CandidateProfile, IMatchRepository, SwipedProfile, UserAnswerData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";
import { InteractionState } from "../interfaces/services/match.service.interface";

export class MatchRepository implements IMatchRepository {
   async getUserPreference(userId: number): Promise<UserPreferenceData | null> {
      const pref = await prisma.partnerPreference.findUnique({ where: { userId } });
      if (!pref) return null;
      return {
         ageFrom: pref.ageFrom,
         ageTo: pref.ageTo,
         heightFrom: pref.heightFrom,
         heightTo: pref.heightTo,
         motherTongue: pref.motherTongue,
         highestEducation: pref.highestEducation,
         occupation: pref.occupation,
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
            // profileStatus: "COMPLETED",
            user: {
               isBlocked: false,
               isDeleted: false,
               isVerified: true,
               id: { not: currentUserId },
            },
            ...(targetGender && { gender: { in: targetGender.in as ("MALE" | "FEMALE" | "OTHER")[] } }),
            id: { notIn: excludedProfileIds },
         },
         include: {
            images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
            answers: { select: { questionId: true, answer: true, score: true } },
            swipesOnMe: { where: { userId: currentUserId } },
            user: {
               select: {
                  profileSwipes: {
                     where: currentUser?.profile?.id ? { targetProfileId: currentUser.profile.id } : { id: -1 },
                  },
                  isVerified: true,
                  createdAt: true,
                  updatedAt: true,
               },
            },
         },
      });

      return profiles.map((p) => ({
         id: p.id,
         userId: p.userId,
         name: p.name,
         isVerified: p.user.isVerified,
         dateOfBirth: p.dateOfBirth,
         heightCm: p.heightCm,
         maritalStatus: p.maritalStatus,
         city: p.city,
         state: p.state,
         country: p.country,
         motherTongue: p.motherTongue,
         highestEducation: p.highestEducation,
         occupation: p.occupation,
         bio: p.bio,
         gender: p.gender,
         images: p.images.map((img) => ({ imageUrl: img.imageUrl, isPrimary: img.isPrimary })),
         answers: p.answers,
         interactionState: this.determineInteractionState(p.swipesOnMe, p.user.profileSwipes),
         createdAt: p.user.createdAt,
         lastLoginAt: p.user.updatedAt,
      }));
   }

   private determineInteractionState(swipesOnMe: Array<{ action: SwipeAction }>, theirSwipesOnMe: Array<{ action: SwipeAction }>): InteractionState {
      const iSentInterest = swipesOnMe.some((s) => s.action === SwipeAction.RIGHT);
      const theySentInterest = theirSwipesOnMe.some((s) => s.action === SwipeAction.RIGHT);

      if (iSentInterest && theySentInterest) return InteractionState.MATCHED;
      if (iSentInterest) return InteractionState.INTEREST_SENT;
      if (theySentInterest) return InteractionState.INTEREST_RECEIVED;
      return InteractionState.NONE;
   }

   async recordSwipe(userId: number, targetProfileId: number, action: SwipeAction): Promise<void> {
      const existing = await prisma.profileSwipe.findFirst({ where: { userId, targetProfileId } });
      if (existing) {
         await prisma.profileSwipe.update({ where: { id: existing.id }, data: { action } });
      } else {
         await prisma.profileSwipe.create({ data: { userId, targetProfileId, action } });
      }
   }
   async getLikedProfiles(userId: number): Promise<CandidateProfile[]> {
      const swipes = await prisma.profileSwipe.findMany({
         where: { userId, action: SwipeAction.RIGHT },
         include: {
            targetProfile: {
               include: {
                  user: { select: { isVerified: true, createdAt: true, updatedAt: true } },
                  images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
                  answers: { select: { questionId: true, answer: true, score: true } },
               },
            },
         },
      });

      return swipes.map((s) => ({
         id: s.targetProfile.id,
         userId: s.targetProfile.userId,
         name: s.targetProfile.name,
         isVerified: s.targetProfile.user.isVerified,
         dateOfBirth: s.targetProfile.dateOfBirth,
         heightCm: s.targetProfile.heightCm,
         maritalStatus: s.targetProfile.maritalStatus,
         city: s.targetProfile.city,
         state: s.targetProfile.state,
         country: s.targetProfile.country,
         motherTongue: s.targetProfile.motherTongue,
         highestEducation: s.targetProfile.highestEducation,
         occupation: s.targetProfile.occupation,
         bio: s.targetProfile.bio,
         gender: s.targetProfile.gender,
         images: s.targetProfile.images.map((img) => ({ imageUrl: img.imageUrl, isPrimary: img.isPrimary })),
         answers: s.targetProfile.answers,
         createdAt: s.targetProfile.user.createdAt,
         lastLoginAt: s.targetProfile.user.updatedAt,
      }));
   }

   async getSentInterests(userId: number): Promise<CandidateProfile[]> {
      const currentUser = await prisma.user.findUnique({ where: { id: userId }, include: { profile: true } });
      if (!currentUser?.profile?.id) return [];

      const swipes = await prisma.profileSwipe.findMany({
         where: { userId, action: SwipeAction.RIGHT },
         include: {
            targetProfile: {
               include: {
                  user: { select: { isVerified: true, createdAt: true, updatedAt: true } },
                  images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
                  answers: { select: { questionId: true, answer: true, score: true } },
               },
            },
         },
      });

      // Find their swipes on me (either they matched or rejected me)
      const theirSwipesOnMe = await prisma.profileSwipe.findMany({
         where: { targetProfileId: currentUser.profile.id },
         select: { userId: true },
      });
      const theirSwipeUserIdSet = new Set(theirSwipesOnMe.map((s) => s.userId));

      // Filter out profiles that have swiped on me
      const validSentInterests = swipes.filter((s) => !theirSwipeUserIdSet.has(s.targetProfile.userId));

      return validSentInterests.map((s) => this.mapToCandidateProfile(s.targetProfile, InteractionState.INTEREST_SENT));
   }

   async getReceivedInterests(userId: number): Promise<CandidateProfile[]> {
      const currentUser = await prisma.user.findUnique({ where: { id: userId }, include: { profile: true } });
      if (!currentUser?.profile?.id) return [];

      const swipes = await prisma.profileSwipe.findMany({
         where: { targetProfileId: currentUser.profile.id, action: SwipeAction.RIGHT },
         include: {
            user: {
               include: {
                  profile: {
                     include: {
                        images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
                        answers: { select: { questionId: true, answer: true, score: true } },
                     },
                  },
               },
            },
         },
      });

      // Filter out received ones that we have already swiped on (whether RIGHT to match or LEFT to reject)
      const mySwipes = await prisma.profileSwipe.findMany({
         where: { userId },
         select: { targetProfileId: true },
      });
      const mySwipeSet = new Set(mySwipes.map((s) => s.targetProfileId));

      const profiles = sweepsToProfiles(swipes.filter((s) => s.user.profile && !mySwipeSet.has(s.user.profile.id)));

      return profiles.map((p: any) => this.mapToCandidateProfile(p, InteractionState.INTEREST_RECEIVED));
   }

   async getMutualMatches(userId: number): Promise<CandidateProfile[]> {
      const currentUser = await prisma.user.findUnique({ where: { id: userId }, include: { profile: true } });
      if (!currentUser?.profile?.id) return [];

      // Find my right swipes
      const mySwipes = await prisma.profileSwipe.findMany({
         where: { userId, action: SwipeAction.RIGHT },
         select: { targetProfileId: true },
      });
      const mySwipeSet = new Set(mySwipes.map((s) => s.targetProfileId));

      // Find their right swipes on me
      const theirSwipes = await prisma.profileSwipe.findMany({
         where: { targetProfileId: currentUser.profile.id, action: SwipeAction.RIGHT },
         include: {
            user: {
               include: {
                  profile: {
                     include: {
                        images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
                        answers: { select: { questionId: true, answer: true, score: true } },
                     },
                  },
               },
            },
         },
      });

      // The intersection
      const matches = theirSwipes.filter((s) => s.user.profile && mySwipeSet.has(s.user.profile.id));
      const profiles = sweepsToProfiles(matches);

      return profiles.map((p: any) => this.mapToCandidateProfile(p, InteractionState.MATCHED));
   }
   async getProfileById(currentUserId: number, profileId: number): Promise<CandidateProfile | null> {
      const currentUser = await prisma.user.findUnique({ where: { id: currentUserId }, include: { profile: true } });

      const p = await prisma.profile.findUnique({
         where: { id: profileId },
         include: {
            images: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
            answers: { select: { questionId: true, answer: true, score: true } },
            swipesOnMe: { where: { userId: currentUserId } },
            user: {
               select: {
                  profileSwipes: {
                     where: currentUser?.profile?.id ? { targetProfileId: currentUser.profile.id } : { id: -1 },
                  },
                  isVerified: true,
                  createdAt: true,
                  updatedAt: true,
               },
            },
         },
      });
      if (!p) return null;

      const interactionState = this.determineInteractionState(p.swipesOnMe, p.user.profileSwipes);
      return this.mapToCandidateProfile(p, interactionState);
   }

   private mapToCandidateProfile(p: any, interactionState?: InteractionState): CandidateProfile {
      return {
         id: p.id,
         userId: p.userId,
         name: p.name,
         isVerified: p.user?.isVerified ?? false,
         dateOfBirth: p.dateOfBirth,
         heightCm: p.heightCm,
         maritalStatus: p.maritalStatus,
         city: p.city,
         state: p.state,
         country: p.country,
         motherTongue: p.motherTongue,
         highestEducation: p.highestEducation,
         occupation: p.occupation,
         bio: p.bio,
         gender: p.gender,
         images: p.images.map((img: any) => ({ imageUrl: img.imageUrl, isPrimary: img.isPrimary })),
         answers: p.answers,
         interactionState,
         createdAt: p.user?.createdAt ?? new Date(),
         lastLoginAt: p.user?.updatedAt ?? new Date(),
      };
   }
}

// helper to safely extract profiles from sweeps having a user with a profile
function sweepsToProfiles(swipes: any[]) {
   return swipes.reduce((acc, current) => {
      if (current.user?.profile) {
         acc.push({
            ...current.user.profile,
            user: { 
               isVerified: current.user.isVerified,
               createdAt: current.user.createdAt,
               updatedAt: current.user.updatedAt,
            },
         });
      }
      return acc;
   }, [] as any[]);
}
