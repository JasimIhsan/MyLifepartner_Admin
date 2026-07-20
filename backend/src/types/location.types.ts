export type LocationSearchType = "country" | "state" | "city";

export interface GooglePlacePrediction {
   placePrediction: {
      place: string; // "places/PLACE_ID"
      placeId: string;
      text: {
         text: string;
         matches: any[];
      };
      structuredFormat: {
         mainText: {
            text: string;
            matches: any[];
         };
         secondaryText: {
            text: string;
         };
      };
      types: string[];
   };
}

export interface GooglePlacesAutocompleteResponse {
   suggestions?: GooglePlacePrediction[];
}

export interface GooglePlaceDetailsResponse {
   id: string;
   name?: string;
   displayName?: {
      text: string;
      languageCode: string;
   };
   formattedAddress: string;
   addressComponents: Array<{
      longText: string;
      shortText: string;
      types: string[];
      languageCode?: string;
   }>;
   location: {
      latitude: number;
      longitude: number;
   };
   types: string[];
}

export interface GoogleReverseGeocodeResult {
   place_id: string;
   formatted_address: string;
   geometry: {
      location: {
         lat: number;
         lng: number;
      };
   };
   types: string[];
   address_components: Array<{
      long_name: string;
      short_name: string;
      types: string[];
   }>;
}

export interface GoogleReverseGeocodeResponse {
   results: GoogleReverseGeocodeResult[];
   status: string;
   error_message?: string;
}

export interface LocationPrediction {
   placeId: string;
   name: string;
   description: string;
   types: string[];
}

export interface LocationDetails {
   placeId: string;
   name: string;
   formattedAddress: string;
   country?: string;
   countryCode?: string;
   state?: string;
   stateCode?: string;
   city?: string;
   latitude?: number;
   longitude?: number;
   types: string[];
   source?: "current_location" | "autocomplete" | "existing_profile";
}
