import rateLimit from "express-rate-limit";

const ONE_HOUR_IN_MS = 60 * 60 * 1000;
const GLOBAL_RATE_LIMIT_MAX_REQUESTS = 10_000;

export const globalLimiter = rateLimit({
   windowMs: ONE_HOUR_IN_MS,
   max: GLOBAL_RATE_LIMIT_MAX_REQUESTS,
   message: {
      success: false,
      message: "Too many requests from this IP. Please try again later.",
   },
   standardHeaders: true,
   legacyHeaders: false,
});
