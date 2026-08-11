import prisma from "@/config/prisma";
import { Prisma } from "@prisma/client";
import { DiscoveryQueryOptions } from "../../types/discovery.types";
import { ApiError } from "../../utils/ApiError";

import { IS3Service } from "@/interfaces/services/s3.service.interface";

const DEFAULT_DISCOVERY_PAGE = 1;
const DEFAULT_DISCOVERY_LIMIT = 20;
const MAX_DISCOVERY_LIMIT = 50;

const discoveryProfileSelect = {
   id: true,
   userId: true,
   name: true,
   gender: true,
   dateOfBirth: true,
   city: true,
   state: true,
   country: true,
   maritalStatus: true,
   motherTongue: true,
   highestEducation: true,
   bio: true,
   languages: true,
   childrenStatus: true,
   smokingHabit: true,
   drinkingHabit: true,
   job: {
      select: {
         name: true,
      },
   },
   images: {
      select: {
         id: true,
         imageUrl: true,
         isPrimary: true,
      },
      orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }],
   },
   user: {
      select: {
         isVerified: true,
         isFoundingMember: true,
         createdAt: true,
         updatedAt: true,
      },
   },
} satisfies Prisma.ProfileSelect;

type DiscoveryProfile = Prisma.ProfileGetPayload<{
   select: typeof discoveryProfileSelect;
}>;

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
      const safePage = this.normalizePositiveInteger(page, DEFAULT_DISCOVERY_PAGE);
      const safeLimit = Math.min(this.normalizePositiveInteger(limit, DEFAULT_DISCOVERY_LIMIT), MAX_DISCOVERY_LIMIT);
      const skip = (safePage - 1) * safeLimit;
      const searchTerm = search?.trim();
      const languageFilters = this.normalizeStringArray(languages);

      const [currentUser, excludedUserIds] = await Promise.all([
         prisma.user.findUnique({
            where: { id: currentUserId },
            select: {
               profile: {
                  select: {
                     gender: true,
                  },
               },
            },
         }),
         this.getExcludedUserIds(currentUserId),
      ]);

      // Ensure the user exists and we know their gender to potentially filter by opposite gender if required.
      if (!currentUser || !currentUser.profile) {
         throw new ApiError(404, "Current user profile not found");
      }

      const userFilter: Prisma.UserWhereInput = {
         isBanned: false,
         isSuspended: false,
         isDeleted: false,
         ...(verifiedOnly && {
            isVerified: true,
         }),
      };

      const whereClause: Prisma.ProfileWhereInput = {
         userId: {
            notIn: [currentUserId, ...excludedUserIds],
         },
         user: userFilter,
      };

      const targetGenderFilter = this.getTargetGenderFilter(currentUser.profile.gender);
      if (targetGenderFilter) {
         whereClause.gender = targetGenderFilter;
      }

      const dateOfBirthFilter = this.buildDateOfBirthFilter(ageFrom, ageTo);
      if (dateOfBirthFilter) {
         whereClause.dateOfBirth = dateOfBirthFilter;
      }

      if (languageFilters.length > 0) {
         whereClause.languages = {
            hasSome: languageFilters,
         };
      }

      if (maritalStatus && maritalStatus.length > 0) {
         whereClause.maritalStatus = {
            in: maritalStatus,
         };
      }

      if (childrenStatus) {
         whereClause.childrenStatus = childrenStatus;
      }

      if (smoking && smoking.length > 0) {
         whereClause.smokingHabit = {
            in: smoking,
         };
      }

      if (drinking && drinking.length > 0) {
         whereClause.drinkingHabit = {
            in: drinking,
         };
      }

      if (searchTerm) {
         whereClause.name = {
            contains: searchTerm,
            mode: "insensitive",
         };
      }

      const [totalCount, profiles] = await Promise.all([
         prisma.profile.count({ where: whereClause }),
         prisma.profile.findMany({
            where: whereClause,
            select: discoveryProfileSelect,
            skip,
            take: safeLimit,
            orderBy: {
               id: "desc",
            },
         }),
      ]);

      const totalPages = Math.ceil(totalCount / safeLimit);
      const hasNextPage = safePage < totalPages;
      const today = new Date();
      const presignedImageUrls = await this.getPresignedImageUrlMap(profiles);

      const mappedProfiles = profiles.map((profile) => this.mapProfile(profile, today, presignedImageUrls));

      return {
         profiles: mappedProfiles,
         pagination: {
            page: safePage,
            limit: safeLimit,
            total: totalCount,
            totalPages,
            hasNextPage,
         },
      };
   }

   private async getExcludedUserIds(userId: number): Promise<number[]> {
      const blocks = await prisma.userBlock.findMany({
         where: {
            OR: [{ blockerUserId: userId }, { blockedUserId: userId }],
         },
         select: {
            blockerUserId: true,
            blockedUserId: true,
         },
      });

      return blocks.map((block) => (block.blockerUserId === userId ? block.blockedUserId : block.blockerUserId));
   }

   private getTargetGenderFilter(gender?: string | null): Prisma.EnumGenderNullableFilter | undefined {
      if (gender === "MALE") {
         return {
            in: ["FEMALE", "OTHER"],
         };
      }

      if (gender === "FEMALE") {
         return {
            in: ["MALE", "OTHER"],
         };
      }

      return undefined;
   }

   private buildDateOfBirthFilter(ageFrom?: number, ageTo?: number): Prisma.DateTimeFilter | undefined {
      if (ageFrom === undefined && ageTo === undefined) {
         return undefined;
      }

      const today = new Date();
      const dateFilters: Prisma.DateTimeFilter = {};

      if (ageTo !== undefined) {
         dateFilters.gte = new Date(today.getFullYear() - ageTo - 1, today.getMonth(), today.getDate() + 1);
      }

      if (ageFrom !== undefined) {
         dateFilters.lte = new Date(today.getFullYear() - ageFrom, today.getMonth(), today.getDate());
      }

      return dateFilters;
   }

   private async getPresignedImageUrlMap(profiles: DiscoveryProfile[]): Promise<Map<string, string>> {
      const imageUrls = new Set<string>();

      for (const profile of profiles) {
         for (const image of profile.images) {
            imageUrls.add(image.imageUrl);
         }
      }

      const presignedUrls = await Promise.all(
         Array.from(imageUrls).map(async (imageUrl) => [imageUrl, await this.s3Service.getPresignedUrl(imageUrl)] as const)
      );

      return new Map(presignedUrls);
   }

   private mapProfile(profile: DiscoveryProfile, today: Date, presignedImageUrls: Map<string, string>) {
      return {
         id: profile.id,
         userId: profile.userId,
         name: profile.name,
         age: this.calculateAge(profile.dateOfBirth, today),
         gender: profile.gender,
         city: profile.city,
         state: profile.state,
         country: profile.country,
         isVerified: profile.user.isVerified,
         isFoundingMember: profile.user.isFoundingMember,
         maritalStatus: profile.maritalStatus,
         motherTongue: profile.motherTongue,
         highestEducation: profile.highestEducation,
         occupation: profile.job?.name || null,
         bio: profile.bio,
         images: profile.images.map((img) => ({
            id: img.id,
            imageUrl: presignedImageUrls.get(img.imageUrl) ?? img.imageUrl,
            isPrimary: img.isPrimary,
         })),
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
   }

   private calculateAge(dateOfBirth: Date | null, today: Date): number {
      if (!dateOfBirth) {
         return 0;
      }

      let age = today.getFullYear() - dateOfBirth.getFullYear();
      const monthDifference = today.getMonth() - dateOfBirth.getMonth();

      if (monthDifference < 0 || (monthDifference === 0 && today.getDate() < dateOfBirth.getDate())) {
         age -= 1;
      }

      return age;
   }

   private normalizePositiveInteger(value: number | undefined, fallback: number): number {
      if (!Number.isFinite(value) || value === undefined) {
         return fallback;
      }

      return Math.max(1, Math.floor(value));
   }

   private normalizeStringArray(values?: string[]): string[] {
      if (!values) {
         return [];
      }

      return values.map((value) => value.trim()).filter(Boolean);
   }
}
