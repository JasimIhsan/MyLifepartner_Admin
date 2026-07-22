import rateLimit from "express-rate-limit";

const ONE_HOUR_IN_MS = 60 * 60 * 1000;
const ONE_MINUTE_IN_MS = 60 * 1000;

/**
 * Global limiter — lowered from 10,000 to 500 to provide meaningful protection
 */
export const globalLimiter = rateLimit({
   windowMs: ONE_HOUR_IN_MS,
   max: 500,
   message: {
      success: false,
      message: "Too many requests from this IP. Please try again later.",
   },
   standardHeaders: true,
   legacyHeaders: false,
});

/**
 * Webhook limiter — applied directly to POST /webhook before auth middleware.
 * Prevents webhook flooding from unauthenticated callers
 */
export const webhookLimiter = rateLimit({
   windowMs: ONE_MINUTE_IN_MS * 5,
   max: 100,
   message: {
      success: false,
      message: "Too many webhook requests. Please retry later.",
   },
   standardHeaders: true,
   legacyHeaders: false,
});

/**
 * Subscription action limiter — applied to /subscribe and /sync endpoints.
 * Prevents repeated plan-change attempts from a single user
 */
export const subscriptionActionLimiter = rateLimit({
   windowMs: ONE_HOUR_IN_MS,
   max: 20,
   message: {
      success: false,
      message: "Too many subscription requests. Please try again later.",
   },
   standardHeaders: true,
   legacyHeaders: false,
});
