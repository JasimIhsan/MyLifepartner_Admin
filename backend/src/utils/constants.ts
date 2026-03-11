export const CACHE_KEYS = {
   OTP: (email: string) => `otp:${email}`,
   REFRESH_TOKEN: (userId: string | number) => `refresh_token:${userId}`,
   OTP_IP_REQ_COUNT: (ip: string) => `otp_ip_count:${ip}`,
   OTP_EMAIL_REQ_COUNT: (email: string) => `otp_email_count:${email}`,
   OTP_VERIFY_ATTEMPTS: (email: string) => `otp_verify_attempts:${email}`,
   OTP_RESEND_LOCK: (email: string) => `otp_resend_lock:${email}`,
   OTP_VERIFIED: (email: string) => `otp_verified:${email}`,
   ACCOUNT_LOCK: (email: string) => `account_lock:${email}`,
   PASSWORD_RESET_TOKEN: (token: string) => `password_reset:${token}`,
};

export const TOKEN_EXPIRY = {
   ACCESS: "15m",
   REFRESH: "7d",
};

export const OTP_CONFIG = {
   EXPIRY: 300, // 5 minutes in seconds
   DEFAULT_OTP: "111111",
};

export const RATE_LIMIT_CONFIG = {
   OTP_REQUEST_EMAIL: 5,
   OTP_REQUEST_IP: 10,
   OTP_VERIFY_ATTEMPTS: 5,
   LOCKOUT_DURATION: 15 * 60, // 15 mins
   RESEND_WAIT: 60, // 60 seconds
   OTP_WINDOW: 60 * 60, // 1 hour
};

export const HTTP_STATUS = {
   OK: 200,
   CREATED: 201,
   BAD_REQUEST: 400,
   UNAUTHORIZED: 401,
   FORBIDDEN: 403,
   NOT_FOUND: 404,
   CONFLICT: 409,
   TOO_MANY_REQUESTS: 429,
   INTERNAL_SERVER_ERROR: 500,
};
