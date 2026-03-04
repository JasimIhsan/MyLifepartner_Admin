import { AxiosError } from "axios";

/**
 * Backend Error Response Structure (matches backend/src/utils/ApiError.ts)
 */
interface ApiErrorResponse {
   statusCode: number;
   message: string;
   success: boolean;
   errors?: unknown[];
   stack?: string;
}

/**
 * Utility to extract a user-friendly error message from an API response,
 * Axios error, or generic Error.
 *
 * @param error The error object caught in a try/catch block
 * @param defaultMessage Fallback message if no specific error message is found
 * @returns {string} A human-readable error message
 */
export const handleApiError = (error: unknown, defaultMessage = "Something went wrong"): string => {
   // 1. Handle Axios Errors (API Responses)
   if (error instanceof AxiosError) {
      const data = error.response?.data as ApiErrorResponse;

      // Priority 1: Backend's custom ApiError message
      if (data?.message) {
         return data.message;
      }

      // Priority 2: Validation errors array (if backend sends complex errors)
      if (data?.errors && Array.isArray(data.errors) && data.errors.length > 0) {
         const firstError = data.errors[0];
         if (typeof firstError === "string") return firstError;
         if (typeof firstError === "object" && firstError !== null && "message" in firstError) return String(firstError.message);
         return JSON.stringify(firstError);
      }

      // Priority 3: Axios-specific network/timeout issues
      if (error.code === "ERR_NETWORK") {
         return "Network error. Please check your internet connection and server status.";
      }
      if (error.code === "ECONNABORTED") {
         return "The request timed out. Please try again.";
      }
      if (error.status === 404) {
         return "Requested resource not found (404).";
      }

      // Priority 4: Axios generic message
      return error.message || defaultMessage;
   }

   // 2. Handle Standard JavaScript Errors
   if (error instanceof Error) {
      return error.message;
   }

   // 3. Fallback for unknown error types
   if (typeof error === "string") {
      return error;
   }

   return defaultMessage;
};
