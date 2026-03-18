import rateLimit from "express-rate-limit";

// Global API Limiter
export const globalLimiter = rateLimit({
   windowMs: 15 * 60 * 1000, // 15 minutes
   max: 100, // Limit each IP to 100 requests per `window`
   message: { success: false, message: 'Too many requests from this IP, please try again in 15 minutes' },
   standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
   legacyHeaders: false, // Disable the `X-RateLimit-*` headers
});

// Strict Auth Limiter
export const authLimiter = rateLimit({
   windowMs: 15 * 60 * 1000, // 15 minutes
   max: 5, // Limit each IP to 5 auth requests per `window`
   message: { success: false, message: 'Too many authentication attempts from this IP. Please try again later.' },
   standardHeaders: true,
   legacyHeaders: false,
});
