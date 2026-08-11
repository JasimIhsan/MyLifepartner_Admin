import { ChildrenStatus, DrinkingHabit, MaritalStatus, SmokingHabit } from "@prisma/client";
import { NextFunction, Request, Response } from "express";
import { DiscoveryService } from "../../services/user/discovery.service";
import { DiscoveryQueryOptions } from "../../types/discovery.types";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

export class DiscoveryController {
   constructor(private readonly discoveryService: DiscoveryService) {}

   public discoverProfiles = asyncHandler(async (req: Request, res: Response, next: NextFunction) => {
      const currentUserId = req.user?.id;

      if (!currentUserId) {
         return res.status(401).json(new ApiResponse(401, null, "Unauthorized"));
      }

      // Parse query parameters
      const { page, limit, ageFrom, ageTo, languages, maritalStatus, childrenStatus, verifiedOnly, smoking, drinking, search } = req.query;

      const options: DiscoveryQueryOptions = {
         page: page ? parseInt(page as string, 10) : 1,
         limit: limit ? parseInt(limit as string, 10) : 20,
         ageFrom: ageFrom ? parseInt(ageFrom as string, 10) : undefined,
         ageTo: ageTo ? parseInt(ageTo as string, 10) : undefined,
         languages: languages ? (languages as string).split(",") : undefined,
         maritalStatus: maritalStatus ? ((maritalStatus as string).split(",") as MaritalStatus[]) : undefined,
         childrenStatus: childrenStatus ? (childrenStatus as ChildrenStatus) : undefined,
         verifiedOnly: verifiedOnly === "true",
         smoking: smoking ? ((smoking as string).split(",") as SmokingHabit[]) : undefined,
         drinking: drinking ? ((drinking as string).split(",") as DrinkingHabit[]) : undefined,
         search: search as string | undefined,
      };

      const result = await this.discoveryService.discoverProfiles(currentUserId, options);

      res.status(200).json(new ApiResponse(200, result, "Profiles fetched successfully"));
   });
}
