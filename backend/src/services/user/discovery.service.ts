import prisma from "@/config/prisma";
import { Prisma } from "@prisma/client";
import { DiscoveryQueryOptions } from "../../types/discovery.types";
import { ApiError } from "../../utils/ApiError";
import { IPrivacyImageMapperService } from "@/interfaces/services/privacy-image-mapper.service.interface";
import { IImageAccessRequestService } from "@/interfaces/services/image-access-request.service.interface";

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
         privacySettings: {
            select: {
               privacyEnabled: true,
               blurredImageUrl: true,
            },
         },
         subscriptions: {
            where: {
               status: {
                  in: ["ACTIVE", "CANCELLED_PENDING_EXPIRY", "BILLING_ISSUE", "GRACE_PERIOD"],
               },
            },
            select: { id: true },
            take: 1,
         },
      },
   },
} satisfies Prisma.ProfileSelect;

type DiscoveryProfile = Prisma.ProfileGetPayload<{
   select: typeof discoveryProfileSelect;
}>;

export class DiscoveryService {
   constructor(
      private readonly privacyImageMapperService: IPrivacyImageMapperService,
      private readonly imageAccessRequestService: IImageAccessRequestService
   ) {}
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

      const [currentUser, excludedUserIds, sentRequestsList] = await Promise.all([
         prisma.user.findUnique({
            where: { id: currentUserId },
            select: {
               profile: {
                  select: {
                     gender: true,
                  },
               },
               privacySettings: {
                  select: {
                     privacyEnabled: true,
                  },
               },
            },
         }),
         this.getExcludedUserIds(currentUserId),
         this.imageAccessRequestService.getSentRequests(currentUserId),
      ]);

      // Ensure the user exists and we know their gender to potentially filter by opposite gender if required.
      if (!currentUser || !currentUser.profile) {
         throw new ApiError(404, "Current user profile not found");
      }

      const viewerPrivacyEnabled = currentUser.privacySettings?.privacyEnabled ?? false;
      const sentRequestsMap = new Map<number, string>();
      for (const req of sentRequestsList) {
         sentRequestsMap.set(req.ownerUserId, req.status);
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

      const candidateUserIds = profiles.map((p) => p.userId);
      const approvedAccessesList =
         candidateUserIds.length > 0
            ? await this.imageAccessRequestService.getApprovedAccessesForViewer(currentUserId, candidateUserIds)
            : [];
      const approvedAccesses = new Set(approvedAccessesList.map((a) => a.ownerUserId));

      const totalPages = Math.ceil(totalCount / safeLimit);
      const hasNextPage = safePage < totalPages;
      const today = new Date();

      const mappedProfiles = await Promise.all(
         profiles.map((profile) =>
            this.mapProfile(profile, today, {
               currentUserId,
               viewerPrivacyEnabled,
               approvedAccesses,
               sentRequestsMap,
            })
         )
      );

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

   private async mapProfile(
      profile: DiscoveryProfile,
      today: Date,
      context: {
         currentUserId: number;
         viewerPrivacyEnabled: boolean;
         approvedAccesses: Set<number>;
         sentRequestsMap: Map<number, string>;
      }
   ) {
      const targetPrivacyEnabled = profile.user.privacySettings?.privacyEnabled ?? false;
      const targetBlurredImageUrl = profile.user.privacySettings?.blurredImageUrl ?? null;
      const hasApprovedAccess = context.approvedAccesses.has(profile.userId);

      const isRestricted = (context.viewerPrivacyEnabled || targetPrivacyEnabled) && !hasApprovedAccess;

      const name = isRestricted
         ? (profile.name ? profile.name.split(" ")[0] : "Unknown")
         : (profile.name ?? "Unknown");

      const mappedImages = await this.privacyImageMapperService.mapImages({
         viewerUserId: context.currentUserId,
         viewerPrivacyEnabled: context.viewerPrivacyEnabled,
         targetUserId: profile.userId,
         targetPrivacyEnabled,
         targetBlurredImageUrl,
         targetImages: profile.images.map((img) => ({
            id: img.id,
            imageUrl: img.imageUrl,
            isPrimary: img.isPrimary,
         })),
         hasApprovedAccess,
      });

      return {
         id: profile.id,
         userId: profile.userId,
         name,
         age: this.calculateAge(profile.dateOfBirth, today),
         gender: profile.gender,
         city: profile.city,
         state: profile.state,
         country: profile.country,
         isVerified: profile.user.isVerified,
         isFoundingMember: profile.user.isFoundingMember,
         isPremium: ("subscriptions" in profile.user ? (profile.user.subscriptions?.length ?? 0) > 0 : false),
         maritalStatus: isRestricted ? null : profile.maritalStatus,
         motherTongue: profile.motherTongue,
         highestEducation: profile.highestEducation,
         occupation: isRestricted ? null : (profile.job?.name || null),
         bio: profile.bio,
         images: mappedImages.map((img) => ({
            id: img.id,
            imageId: img.imageId,
            imageUrl: img.presignedImageUrl ?? "",
            presignedImageUrl: img.presignedImageUrl ?? "",
            isPrimary: img.isPrimary,
            isBlurred: img.isBlurred ?? false,
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
         viewerPrivacyEnabled: context.viewerPrivacyEnabled,
         targetPrivacyEnabled,
         imageAccessRequestStatus: context.sentRequestsMap.get(profile.userId) ?? null,
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
