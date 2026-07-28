import { z } from "zod";

export const searchLocationSchema = z.object({
   query: z.object({
      query: z.string().min(2, "Query must be at least 2 characters"),
      type: z.enum(["country", "state", "city"]),
      sessionToken: z.string().uuid("Invalid session token"),
      countryCode: z.string().length(2, "Country code must be 2 characters").optional(),
      stateName: z.string().optional(),
   }),
});

export const placeDetailsSchema = z.object({
   params: z.object({
      placeId: z.string().min(1, "Place ID is required"),
   }),
});

export const reverseGeocodeSchema = z.object({
   query: z.object({
      latitude: z.coerce
         .number()
         .min(-90, "Latitude must be between -90 and 90")
         .max(90, "Latitude must be between -90 and 90"),
      longitude: z.coerce
         .number()
         .min(-180, "Longitude must be between -180 and 180")
         .max(180, "Longitude must be between -180 and 180"),
   }),
});
