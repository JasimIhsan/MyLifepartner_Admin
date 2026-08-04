import prisma from "@/config/prisma";
import { Gender, Prisma } from "@prisma/client";
import { CandidateProfile, IMatchRepository, SwipedProfile, UserAnswerData, UserPreferenceData } from "../interfaces/repositories/match.repository.interface";
import { InteractionState, SwipeAction } from "../interfaces/services/match.service.interface";

const candidateProfileInclude = {
   user: {
      select: {
         isVerified: true,
         createdAt: true,
         updatedAt: true,
         privacySettings: true,
      },
   },
   images: {
      orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }],
   },
   answers: {
      select: {
         questionId: true,
         answer: true,
         score: true,
      },
   },
   job: true,
} satisfies Prisma.ProfileInclude;

type CandidateProfilePayload = Prisma.ProfileGetPayload<{
   include: typeof candidateProfileInclude;
}>;

type ProfileWithInteractionData = Prisma.ProfileGetPayload<{
   include: {
      job: true;
      images: {
         orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }];
      };
      answers: {
         select: {
            questionId: true;
            answer: true;
            score: true;
         };
      };
      swipesOnMe: {
         where: {
            userId: number;
         };
      };
      user: {
         select: {
            profileSwipes: true;
            isVerified: true;
            createdAt: true;
            updatedAt: true;
            privacySettings: true;
         };
      };
   };
}>;

type SwipeWithUserProfile = Prisma.ProfileSwipeGetPayload<{
   include: {
      user: {
         include: {
            profile: {
               include: typeof candidateProfileInclude;
            };
         };
      };
   };
}>;

export class MatchRepository implements IMatchRepository {
   /**
    * Gets user partner preference.
    *
    * @param userId - User ID.
    * @returns User preference data, or null if not found.
    */
   async getUserPreference(userId: number): Promise<UserPreferenceData | null> {
      const preference = await prisma.partnerPreference.findUnique({
         where: {
            userId,
         },
      });

      if (!preference) {
         return null;
      }

      return {
         ageFrom: preference.ageFrom,
         ageTo: preference.ageTo,
         motherTongue: preference.motherTongue,
      };
   }

   /**
    * Gets user answers.
    *
    * @param userId - User ID.
    * @returns User answers.
    */
   async getUserAnswers(userId: number): Promise<UserAnswerData[]> {
      return prisma.userAnswer.findMany({
         where: {
            profile: {
               userId,
            },
         },
         select: {
            questionId: true,
            answer: true,
            score: true,
         },
      });
   }

   /**
    * Gets swiped profile IDs of a user.
    *
    * @param userId - User ID.
    * @returns Swiped profiles.
    */
   async getSwipedProfileIds(userId: number): Promise<SwipedProfile[]> {
      const swipes = await prisma.profileSwipe.findMany({
         where: {
            userId,
         },
         select: {
            targetProfileId: true,
            action: true,
         },
      });

      return swipes as unknown as SwipedProfile[];
   }

   private async getExcludedUserIds(userId: number): Promise<number[]> {
      const blocks = await prisma.userBlock.findMany({
         where: {
            OR: [
               { blockerUserId: userId },
               { blockedUserId: userId },
            ],
         },
         select: {
            blockerUserId: true,
            blockedUserId: true,
         },
      });

      const excludedUserIdsSet = new Set<number>();
      for (const block of blocks) {
         if (block.blockerUserId === userId) {
            excludedUserIdsSet.add(block.blockedUserId);
         } else {
            excludedUserIdsSet.add(block.blockerUserId);
         }
      }
      return Array.from(excludedUserIdsSet);
   }

   /**
    * Gets candidate profiles for matching.
    *
    * @param currentUserId - Current user ID.
    * @param excludedProfileIds - Profile IDs to exclude.
    * @returns Candidate profiles.
    */
   async getCandidateProfiles(currentUserId: number, excludedProfileIds: number[]): Promise<CandidateProfile[]> {
      const excludedBlockUserIds = await this.getExcludedUserIds(currentUserId);
      const currentUser = await prisma.user.findUnique({
         where: {
            id: currentUserId,
         },
         include: {
            profile: true,
         },
      });

      const targetGenderFilter = this.getTargetGenderFilter(currentUser?.profile?.gender);

      const profiles = await prisma.profile.findMany({
         where: {
            user: {
               isBanned: false,
               isSuspended: false,
               isDeleted: false,
               isVerified: true,
               id: {
                  notIn: [currentUserId, ...excludedBlockUserIds],
               },
            },
            ...(targetGenderFilter && {
               gender: targetGenderFilter,
            }),
            id: {
               notIn: excludedProfileIds,
            },
         },
         include: {
            job: true,
            images: {
               orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }],
            },
            answers: {
               select: {
                  questionId: true,
                  answer: true,
                  score: true,
               },
            },
            swipesOnMe: {
               where: {
                  userId: currentUserId,
               },
            },
            user: {
               select: {
                  profileSwipes: {
                     where: currentUser?.profile?.id
                        ? {
                             targetProfileId: currentUser.profile.id,
                          }
                        : {
                             id: -1,
                          },
                  },
                  isVerified: true,
                  createdAt: true,
                  updatedAt: true,
                  privacySettings: true,
               },
            },
         },
      });

      return profiles.map((profile) => {
         const interactionState = this.determineInteractionState(profile.swipesOnMe as unknown as { action: SwipeAction }[], profile.user.profileSwipes as unknown as { action: SwipeAction }[]);

         return this.mapToCandidateProfile(profile, interactionState);
      });
   }

   /**
    * Records a user swipe.
    *
    * @param userId - User ID.
    * @param targetProfileId - Target profile ID.
    * @param action - Swipe action.
    * @returns Nothing.
    */
   async recordSwipe(userId: number, targetProfileId: number, action: SwipeAction): Promise<void> {
      const existingSwipe = await prisma.profileSwipe.findFirst({
         where: {
            userId,
            targetProfileId,
         },
      });

      if (existingSwipe) {
         await prisma.profileSwipe.update({
            where: {
               id: existingSwipe.id,
            },
            data: {
               action,
            },
         });

         return;
      }

      await prisma.profileSwipe.create({
         data: {
            userId,
            targetProfileId,
            action,
         },
      });
   }

   /**
    * Gets liked profiles of a user.
    *
    * @param userId - User ID.
    * @returns Liked candidate profiles.
    */
   async getLikedProfiles(userId: number): Promise<CandidateProfile[]> {
      const excludedBlockUserIds = await this.getExcludedUserIds(userId);
      const swipes = await prisma.profileSwipe.findMany({
         where: {
            userId,
            action: SwipeAction.RIGHT,
            targetProfile: {
               userId: {
                  notIn: excludedBlockUserIds,
               }
            }
         },
         include: {
            targetProfile: {
               include: candidateProfileInclude,
            },
         },
      });

      return swipes.map((swipe) => this.mapToCandidateProfile(swipe.targetProfile));
   }

   /**
    * Gets sent interests.
    *
    * @param userId - User ID.
    * @returns Sent interest profiles.
    */
   async getSentInterests(userId: number): Promise<CandidateProfile[]> {
      const currentProfile = await this.getUserProfile(userId);
      const excludedBlockUserIds = await this.getExcludedUserIds(userId);

      if (!currentProfile) {
         return [];
      }

      const swipes = await prisma.profileSwipe.findMany({
         where: {
            userId,
            action: SwipeAction.RIGHT,
            targetProfile: {
               userId: { notIn: excludedBlockUserIds },
            },
         },
         include: {
            targetProfile: {
               include: candidateProfileInclude,
            },
         },
      });

      const theirSwipesOnMe = await prisma.profileSwipe.findMany({
         where: {
            targetProfileId: currentProfile.id,
         },
         select: {
            userId: true,
         },
      });

      const theirSwipeUserIds = new Set(theirSwipesOnMe.map((swipe) => swipe.userId));

      return swipes.filter((swipe) => !theirSwipeUserIds.has(swipe.targetProfile.userId)).map((swipe) => this.mapToCandidateProfile(swipe.targetProfile, InteractionState.INTEREST_SENT));
   }

   /**
    * Gets received interests.
    *
    * @param userId - User ID.
    * @returns Received interest profiles.
    */
   async getReceivedInterests(userId: number): Promise<CandidateProfile[]> {
      const currentProfile = await this.getUserProfile(userId);
      const excludedBlockUserIds = await this.getExcludedUserIds(userId);

      if (!currentProfile) {
         return [];
      }

      const swipes = await prisma.profileSwipe.findMany({
         where: {
            targetProfileId: currentProfile.id,
            action: SwipeAction.RIGHT,
            userId: {
               notIn: excludedBlockUserIds,
            }
         },
         include: {
            user: {
               include: {
                  profile: {
                     include: candidateProfileInclude,
                  },
               },
            },
         },
      });

      const mySwipes = await prisma.profileSwipe.findMany({
         where: {
            userId,
         },
         select: {
            targetProfileId: true,
         },
      });

      const mySwipedProfileIds = new Set(mySwipes.map((swipe) => swipe.targetProfileId));

      return this.swipesToProfiles(swipes)
         .filter((profile) => !mySwipedProfileIds.has(profile.id))
         .map((profile) => this.mapToCandidateProfile(profile, InteractionState.INTEREST_RECEIVED));
   }

   /**
    * Gets mutual matches.
    *
    * @param userId - User ID.
    * @returns Mutual matched profiles.
    */
   async getMutualMatches(userId: number): Promise<CandidateProfile[]> {
      const currentProfile = await this.getUserProfile(userId);
      const excludedBlockUserIds = await this.getExcludedUserIds(userId);

      if (!currentProfile) {
         return [];
      }

      const mySwipes = await prisma.profileSwipe.findMany({
         where: {
            userId,
            action: SwipeAction.RIGHT,
         },
         select: {
            targetProfileId: true,
         },
      });

      const mySwipedProfileIds = new Set(mySwipes.map((swipe) => swipe.targetProfileId));

      const theirSwipes = await prisma.profileSwipe.findMany({
         where: {
            targetProfileId: currentProfile.id,
            action: SwipeAction.RIGHT,
            userId: { notIn: excludedBlockUserIds },
         },
         include: {
            user: {
               include: {
                  profile: {
                     include: candidateProfileInclude,
                  },
               },
            },
         },
      });

      return this.swipesToProfiles(theirSwipes)
         .filter((profile) => mySwipedProfileIds.has(profile.id))
         .map((profile) => this.mapToCandidateProfile(profile, InteractionState.MATCHED));
   }

   /**
    * Gets a profile by ID.
    *
    * @param currentUserId - Current user ID.
    * @param profileId - Profile ID.
    * @returns Candidate profile, or null if not found.
    */
   async getProfileById(currentUserId: number, profileId: number): Promise<CandidateProfile | null> {
      const currentProfile = await this.getUserProfile(currentUserId);

      const profile = await prisma.profile.findUnique({
         where: {
            id: profileId,
         },
         include: {
            job: true,
            images: {
               orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }],
            },
            answers: {
               select: {
                  questionId: true,
                  answer: true,
                  score: true,
               },
            },
            swipesOnMe: {
               where: {
                  userId: currentUserId,
               },
            },
            user: {
               select: {
                  profileSwipes: {
                     where: currentProfile
                        ? {
                             targetProfileId: currentProfile.id,
                          }
                        : {
                             id: -1,
                          },
                  },
                  isVerified: true,
                  createdAt: true,
                  updatedAt: true,
                  privacySettings: true,
                  blockedBy: {
                     where: {
                        blockerUserId: currentUserId,
                     }
                  }
               },
            },
         },
      });

      if (!profile) {
         return null;
      }

      const interactionState = this.determineInteractionState(profile.swipesOnMe as unknown as { action: SwipeAction }[], profile.user.profileSwipes as unknown as { action: SwipeAction }[]);

      const candidateProfile = this.mapToCandidateProfile(profile, interactionState);
      candidateProfile.isBlocked = profile.user.blockedBy.length > 0;

      return candidateProfile;
   }

   /**
    * Gets user profile.
    *
    * @param userId - User ID.
    * @returns User profile, or null if not found.
    */
   private async getUserProfile(userId: number) {
      const user = await prisma.user.findUnique({
         where: {
            id: userId,
         },
         include: {
            profile: true,
         },
      });

      return user?.profile ?? null;
   }

   /**
    * Gets target gender filter.
    *
    * @param gender - Current user gender.
    * @returns Target gender filter, or undefined.
    */
   private getTargetGenderFilter(gender?: string | null) {
      if (gender === "MALE") {
         return {
            in: [Gender.FEMALE, Gender.OTHER],
         };
      }

      if (gender === "FEMALE") {
         return {
            in: [Gender.MALE, Gender.OTHER],
         };
      }

      return undefined;
   }

   /**
    * Gets interaction state between users.
    *
    * @param mySwipesOnProfile - Current user's swipes on target profile.
    * @param theirSwipesOnMe - Target user's swipes on current user.
    * @returns Interaction state.
    */
   private determineInteractionState(mySwipesOnProfile: Array<{ action: SwipeAction }>, theirSwipesOnMe: Array<{ action: SwipeAction }>): InteractionState {
      const iSentInterest = mySwipesOnProfile.some((swipe) => swipe.action === SwipeAction.RIGHT);

      const theySentInterest = theirSwipesOnMe.some((swipe) => swipe.action === SwipeAction.RIGHT);

      if (iSentInterest && theySentInterest) {
         return InteractionState.MATCHED;
      }

      if (iSentInterest) {
         return InteractionState.INTEREST_SENT;
      }

      if (theySentInterest) {
         return InteractionState.INTEREST_RECEIVED;
      }

      return InteractionState.NONE;
   }

   /**
    * Maps profile data to candidate profile.
    *
    * @param profile - Profile data.
    * @param interactionState - Optional interaction state.
    * @returns Candidate profile.
    */
   private mapToCandidateProfile(profile: CandidateProfilePayload | ProfileWithInteractionData, interactionState?: InteractionState): CandidateProfile {
      return {
         id: profile.id,
         userId: profile.userId,
         name: profile.name,
         isVerified: profile.user.isVerified,
         dateOfBirth: profile.dateOfBirth,
         maritalStatus: profile.maritalStatus,
         city: profile.city,
         state: profile.state,
         country: profile.country,
         motherTongue: profile.motherTongue,
         highestEducation: profile.highestEducation,
         occupation: profile.job?.name || null,
         bio: profile.bio,
         gender: profile.gender,
         privacyEnabled: profile.user.privacySettings?.privacyEnabled ?? false,
         blurredImageUrl: profile.user.privacySettings?.blurredImageUrl ?? null,
         images: profile.images.map((image) => ({
            id: image.id,
            imageUrl: image.imageUrl,
            isPrimary: image.isPrimary,
         })),
         answers: profile.answers,
         interactionState,
         createdAt: profile.user.createdAt,
         lastLoginAt: profile.user.updatedAt,
      };
   }

   async getViewerPrivacyStatus(userId: number): Promise<boolean> {
      const settings = await prisma.privacySettings.findUnique({
         where: { userId },
         select: { privacyEnabled: true },
      });
      return settings?.privacyEnabled ?? false;
   }

   /**
    * Extracts profiles from profile swipes.
    *
    * @param swipes - Profile swipes with user profile data.
    * @returns Candidate profile payloads.
    */
   private swipesToProfiles(swipes: SwipeWithUserProfile[]): CandidateProfilePayload[] {
      return swipes.map((swipe) => swipe.user.profile).filter((profile): profile is CandidateProfilePayload => Boolean(profile));
   }

   /**
    * Deletes a user swipe record.
    *
    * @param userId - User ID.
    * @param targetProfileId - Target profile ID.
    * @returns True if a swipe was deleted.
    */
   async deleteSwipe(userId: number, targetProfileId: number): Promise<boolean> {
      const deleteResult = await prisma.profileSwipe.deleteMany({
         where: {
            userId,
            targetProfileId,
         },
      });

      return deleteResult.count > 0;
   }

   /**
    * Gets notification context for a swipe action.
    *
    * @param userId - Swiper user ID.
    * @param targetProfileId - Target profile ID.
    * @returns Swipe notification context, or null if profiles not found.
    */
   async getSwipeNotificationContext(userId: number, targetProfileId: number): Promise<import("../interfaces/repositories/match.repository.interface").SwipeNotificationContext | null> {
      const swiperProfile = await prisma.profile.findFirst({
         where: { userId },
         select: { id: true, userId: true, name: true },
      });

      const targetProfile = await prisma.profile.findUnique({
         where: { id: targetProfileId },
         select: { id: true, userId: true, name: true },
      });

      if (!swiperProfile || !targetProfile) {
         return null;
      }

      const mutualSwipe = await prisma.profileSwipe.findFirst({
         where: {
            userId: targetProfile.userId,
            targetProfileId: swiperProfile.id,
            action: SwipeAction.RIGHT,
         },
      });

      return {
         swiperUserId: swiperProfile.userId,
         swiperName: swiperProfile.name || "Someone",
         targetUserId: targetProfile.userId,
         targetName: targetProfile.name || "Someone",
         isMutualMatch: Boolean(mutualSwipe),
      };
   }
}

