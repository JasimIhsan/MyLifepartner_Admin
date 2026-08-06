import prisma from "@/config/prisma";
import { Prisma } from "@prisma/client";
import { DiscoveryQueryOptions } from "../../types/discovery.types";
import { ApiError } from "../../utils/ApiError";

import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { S3Service } from "../s3.service";

const candidateProfileInclude = {
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
   user: {
      select: {
         isVerified: true,
         createdAt: true,
         updatedAt: true,
         privacySettings: true,
      },
   },
} satisfies Prisma.ProfileInclude;

export class DiscoveryService {
   constructor(private readonly s3Service: IS3Service) {}
   /**
    * Discovers profiles based on filter criteria.
    *
    * @param currentUserId - The ID of the user requesting discovery
    * @param options - Filtering and pagination options
    */
   async discoverProfiles(currentUserId: number, options: DiscoveryQueryOptions) {
      const { page = 1, limit = 20, ageFrom, ageTo, languages, maritalStatus, childrenStatus, verifiedOnly, smoking, drinking, search } = options;

      const skip = (page - 1) * limit;

      // Ensure the user exists and we know their gender to potentially filter by opposite gender if required
      const currentUser = await prisma.user.findUnique({
         where: { id: currentUserId },
         include: { profile: true },
      });

      if (!currentUser || !currentUser.profile) {
         throw new ApiError(404, "Current user profile not found");
      }

      // Base query: exclude self, blocked, deleted, and ensure they are verified (or whatever the baseline is)
      const whereClause: Prisma.ProfileWhereInput = {
         user: {
            id: { not: currentUserId },
            isBanned: false,
            isSuspended: false,
            isDeleted: false,
         },
      };

      if (verifiedOnly) {
         whereClause.user = {
            ...(whereClause.user as object),
            isVerified: true,
         };
      }

      // Opposite gender filtering as default behaviour in matchmaking (can adjust if needed)
      if (currentUser.profile.gender === "MALE") {
         whereClause.gender = { in: ["FEMALE", "OTHER"] };
      } else if (currentUser.profile.gender === "FEMALE") {
         whereClause.gender = { in: ["MALE", "OTHER"] };
      }

      // Age filtering
      if (ageFrom !== undefined || ageTo !== undefined) {
         const today = new Date();
         const dateFilters: Prisma.DateTimeFilter = {};

         if (ageTo !== undefined) {
            // Min date of birth (oldest)
            const minDate = new Date(today.getFullYear() - ageTo - 1, today.getMonth(), today.getDate() + 1);
            dateFilters.gte = minDate;
         }

         if (ageFrom !== undefined) {
            // Max date of birth (youngest)
            const maxDate = new Date(today.getFullYear() - ageFrom, today.getMonth(), today.getDate());
            dateFilters.lte = maxDate;
         }

         whereClause.dateOfBirth = dateFilters;
      }

      // Languages filtering (array overlap)
      if (languages && languages.length > 0) {
         whereClause.languages = {
            hasSome: languages,
         };
      }

      // Marital status
      if (maritalStatus && maritalStatus.length > 0) {
         whereClause.maritalStatus = {
            in: maritalStatus,
         };
      }

      // Children status
      if (childrenStatus) {
         whereClause.childrenStatus = childrenStatus;
      }

      // Smoking habit
      if (smoking && smoking.length > 0) {
         whereClause.smokingHabit = {
            in: smoking,
         };
      }

      // Drinking habit
      if (drinking && drinking.length > 0) {
         whereClause.drinkingHabit = {
            in: drinking,
         };
      }

      // Search by name
      if (search && search.trim() !== "") {
         whereClause.name = {
            contains: search.trim(),
            mode: "insensitive",
         };
      }

      // Execute query with pagination
      const [totalCount, profiles] = await Promise.all([
         prisma.profile.count({ where: whereClause }),
         prisma.profile.findMany({
            where: whereClause,
            include: candidateProfileInclude,
            skip,
            take: limit,
            orderBy: {
               id: "desc", // Simple default sorting
            },
         }),
      ]);

      const totalPages = Math.ceil(totalCount / limit);
      const hasNextPage = page < totalPages;

      // Transform raw profiles to standard output format
      const mappedProfiles = await Promise.all(
         profiles.map(async (profile) => {
            // Age calculation
            let age = 0;
            if (profile.dateOfBirth) {
               const today = new Date();
               age = today.getFullYear() - profile.dateOfBirth.getFullYear();
               const m = today.getMonth() - profile.dateOfBirth.getMonth();
               if (m < 0 || (m === 0 && today.getDate() < profile.dateOfBirth.getDate())) {
                  age--;
               }
            }

            const images = await Promise.all(
               profile.images.map(async (img) => ({
                  id: img.id,
                  imageUrl: await this.s3Service.getPresignedUrl(img.imageUrl),
                  isPrimary: img.isPrimary,
               }))
            );

            return {
               id: profile.id,
               userId: profile.userId,
               name: profile.name,
               age,
               gender: profile.gender,
               city: profile.city,
               state: profile.state,
               country: profile.country,
               isVerified: profile.user.isVerified,
               maritalStatus: profile.maritalStatus,
               motherTongue: profile.motherTongue,
               highestEducation: profile.highestEducation,
               occupation: profile.job?.name || null,
               bio: profile.bio,
               images,
               languages: profile.languages,
               childrenStatus: profile.childrenStatus,
               smokingHabit: profile.smokingHabit,
               drinkingHabit: profile.drinkingHabit,
               matchPercentage: 0,
               compatibilityHighlights: [],
               interactionState: "NONE",
               createdAt: profile.user.createdAt.toISOString(),
               lastLoginAt: profile.user.updatedAt.toISOString(),
            };
         })
      );

      return {
         profiles: mappedProfiles,
         pagination: {
            page,
            limit,
            total: totalCount,
            totalPages,
            hasNextPage,
         },
      };
   }
}
