import { env } from "@config/env";
import { ApiError } from "@utils/ApiError";
import { GooglePlaceDetailsResponse, GooglePlacesAutocompleteResponse, GoogleReverseGeocodeResponse, GoogleReverseGeocodeResult, LocationDetails, LocationPrediction, LocationSearchType } from "../../types/location.types";

export class LocationService {
   private static readonly PLACES_API_URL = "https://places.googleapis.com/v1";
   private static readonly GEOCODING_API_URL = "https://maps.googleapis.com/maps/api/geocode/json";

   public static async searchLocations(query: string, type: LocationSearchType, sessionToken: string, countryCode?: string, stateName?: string): Promise<LocationPrediction[]> {
      const apiKey = env.GOOGLE_PLACES_API_KEY;
      if (!apiKey) {
         throw new ApiError(500, "Google Maps API key is not configured");
      }

      let includedPrimaryTypes: string[] = [];
      let input = query;

      switch (type) {
         case "country":
            includedPrimaryTypes = ["country"];
            break;
         case "state":
            includedPrimaryTypes = ["administrative_area_level_1"];
            break;
         case "city":
            includedPrimaryTypes = ["locality", "administrative_area_level_3", "postal_town"];
            if (stateName) {
               input = `${query}, ${stateName}`;
            }
            break;
      }

      const requestBody: any = {
         input,
         includedPrimaryTypes,
         sessionToken,
         languageCode: "en",
      };

      if (countryCode && (type === "state" || type === "city")) {
         requestBody.includedRegionCodes = [countryCode.toLowerCase()];
      }

      try {
         const response = await fetch(`${this.PLACES_API_URL}/places:autocomplete`, {
            method: "POST",
            headers: {
               "Content-Type": "application/json",
               "X-Goog-Api-Key": apiKey,
            },
            body: JSON.stringify(requestBody),
         });

         if (!response.ok) {
            const err = await response.text();
            throw new ApiError(response.status, `Google API error: ${err}`);
         }

         const data = (await response.json()) as GooglePlacesAutocompleteResponse;

         if (!data.suggestions) {
            return [];
         }

         return data.suggestions.map((s) => {
            const placeId = s.placePrediction.place.replace("places/", "");
            return {
               placeId,
               name: s.placePrediction.structuredFormat.mainText.text,
               description: s.placePrediction.structuredFormat.secondaryText?.text || s.placePrediction.text.text,
               types: s.placePrediction.types || [],
            };
         });
      } catch (error) {
         if (error instanceof ApiError) throw error;
         throw new ApiError(500, "Failed to fetch locations from Google API");
      }
   }

   public static async getPlaceDetails(placeId: string): Promise<LocationDetails> {
      const apiKey = env.GOOGLE_PLACES_API_KEY;

      const formattedPlaceId = placeId.startsWith("places/") ? placeId : `places/${placeId}`;

      try {
         const response = await fetch(`${this.PLACES_API_URL}/${formattedPlaceId}`, {
            method: "GET",
            headers: {
               "X-Goog-Api-Key": apiKey,
               "X-Goog-FieldMask": "id,displayName,formattedAddress,addressComponents,location,types",
            },
         });

         if (!response.ok) {
            const err = await response.text();
            throw new ApiError(response.status, `Google API error: ${err}`);
         }

         const data = (await response.json()) as GooglePlaceDetailsResponse;

         return this.parsePlaceDetails(data);
      } catch (error) {
         if (error instanceof ApiError) throw error;
         throw new ApiError(500, "Failed to fetch place details");
      }
   }

   public static async reverseGeocode(latitude: number, longitude: number): Promise<LocationDetails> {
      const apiKey = env.GOOGLE_PLACES_API_KEY;

      try {
         const response = await fetch(`${this.GEOCODING_API_URL}?latlng=${latitude},${longitude}&key=${apiKey}&language=en`);

         if (!response.ok) {
            const err = await response.text();
            throw new ApiError(response.status, `Google Geocoding API error: ${err}`);
         }

         const data = (await response.json()) as GoogleReverseGeocodeResponse;

         if (data.status !== "OK" || !data.results || data.results.length === 0) {
            if (data.status === "REQUEST_DENIED") {
               throw new ApiError(400, `Google Geocoding API denied request: ${data.error_message}`);
            }
            throw new ApiError(404, `Location not found (Status: ${data.status})`);
         }

         // Prefer locality, then postal_town, then admin_area_2, then admin_area_3
         const preferredTypes = ["locality", "postal_town", "administrative_area_level_2", "administrative_area_level_3"];
         let bestResult = data.results.find((r) => r.types.some((t) => preferredTypes.includes(t)));

         if (!bestResult) {
            bestResult = data.results[0]; // fallback to first result
         }

         return this.parseReverseGeocodeResult(bestResult, latitude, longitude);
      } catch (error) {
         if (error instanceof ApiError) throw error;
         throw new ApiError(500, "Failed to reverse geocode");
      }
   }

   private static parsePlaceDetails(data: GooglePlaceDetailsResponse): LocationDetails {
      let country = "";
      let countryCode = "";
      let state = "";
      let stateCode = "";
      let city = "";

      for (const component of data.addressComponents || []) {
         if (component.types.includes("country")) {
            country = component.longText;
            countryCode = component.shortText;
         }
         if (component.types.includes("administrative_area_level_1")) {
            state = component.longText;
            stateCode = component.shortText;
         }
         // City resolution
         if (!city && (component.types.includes("locality") || component.types.includes("postal_town") || component.types.includes("administrative_area_level_2") || component.types.includes("administrative_area_level_3") || component.types.includes("sublocality_level_1") || component.types.includes("sublocality"))) {
            city = component.longText;
         }
      }

      return {
         placeId: data.id.replace("places/", ""),
         name: data.displayName?.text || city || state || country,
         formattedAddress: data.formattedAddress,
         country: country || undefined,
         countryCode: countryCode || undefined,
         state: state || undefined,
         stateCode: stateCode || undefined,
         city: city || undefined,
         latitude: data.location?.latitude,
         longitude: data.location?.longitude,
         types: data.types || [],
         source: "autocomplete",
      };
   }

   private static parseReverseGeocodeResult(result: GoogleReverseGeocodeResult, latitude: number, longitude: number): LocationDetails {
      let country = "";
      let countryCode = "";
      let state = "";
      let stateCode = "";
      let city = "";

      for (const component of result.address_components || []) {
         if (component.types.includes("country")) {
            country = component.long_name;
            countryCode = component.short_name;
         }
         if (component.types.includes("administrative_area_level_1")) {
            state = component.long_name;
            stateCode = component.short_name;
         }
         if (!city && (component.types.includes("locality") || component.types.includes("postal_town") || component.types.includes("administrative_area_level_2") || component.types.includes("administrative_area_level_3") || component.types.includes("sublocality_level_1") || component.types.includes("sublocality"))) {
            city = component.long_name;
         }
      }

      return {
         placeId: result.place_id,
         name: city || state || country,
         formattedAddress: result.formatted_address,
         country: country || undefined,
         countryCode: countryCode || undefined,
         state: state || undefined,
         stateCode: stateCode || undefined,
         city: city || undefined,
         latitude,
         longitude,
         types: result.types || [],
         source: "current_location",
      };
   }
}
