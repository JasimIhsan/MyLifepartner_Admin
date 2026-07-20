import { Request, Response } from "express";
import { ApiResponse } from "@utils/ApiResponse";
import { asyncHandler } from "@utils/asyncHandler";
import { LocationService } from "../../services/user/location.service";
import {
   placeDetailsSchema,
   reverseGeocodeSchema,
   searchLocationSchema,
} from "../../validations/location.schema";
import { LocationSearchType } from "../../types/location.types";

export const searchLocations = asyncHandler(async (req: Request, res: Response) => {
   const { query, type, sessionToken, countryCode, stateName } = searchLocationSchema.parse({
      query: req.query,
   }).query;

   const results = await LocationService.searchLocations(
      query,
      type as LocationSearchType,
      sessionToken,
      countryCode,
      stateName
   );

   return res
      .status(200)
      .json(new ApiResponse(200, results, "Locations retrieved successfully"));
});

export const getPlaceDetails = asyncHandler(async (req: Request, res: Response) => {
   const { placeId } = placeDetailsSchema.parse({ params: req.params }).params;

   const details = await LocationService.getPlaceDetails(placeId);

   return res
      .status(200)
      .json(new ApiResponse(200, details, "Location details retrieved successfully"));
});

export const reverseGeocode = asyncHandler(async (req: Request, res: Response) => {
   const { latitude, longitude } = reverseGeocodeSchema.parse({ query: req.query }).query;

   const details = await LocationService.reverseGeocode(latitude, longitude);

   return res
      .status(200)
      .json(new ApiResponse(200, details, "Current location resolved successfully"));
});
