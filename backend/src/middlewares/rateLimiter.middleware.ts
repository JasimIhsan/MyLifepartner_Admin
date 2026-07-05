import rateLimit from "express-rate-limit";

// Global API Limiter
export const globalLimiter = rateLimit({
   windowMs: 60 * 60 * 1000, // 15 minutes
   max: 10000, // Limit each IP to 100 requests per `window`
   message: { success: false, message: "Too many requests from this IP, please try again in 15 minutes" },
   standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
   legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});
