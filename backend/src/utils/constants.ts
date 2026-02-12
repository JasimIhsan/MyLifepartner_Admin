export const CACHE_KEYS = {
   OTP: (mobileNumber: string) => `otp:${mobileNumber}`,
   REFRESH_TOKEN: (userId: string | number) => `refresh_token:${userId}`,
};

export const TOKEN_EXPIRY = {
   ACCESS: "15m",
   REFRESH: "7d",
};

export const OTP_CONFIG = {
   EXPIRY: 300, // 5 minutes in seconds
   DEFAULT_OTP: "111111",
};

export const HTTP_STATUS = {
   OK: 200,
   CREATED: 201,
   BAD_REQUEST: 400,
   UNAUTHORIZED: 401,
   FORBIDDEN: 403,
   NOT_FOUND: 404,
   CONFLICT: 409,
   INTERNAL_SERVER_ERROR: 500,
};
