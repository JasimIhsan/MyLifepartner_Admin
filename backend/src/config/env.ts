import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
   APP_NAME: z.string().default("LPA Backend"),
   BASE_URL: z.string().url().default("http://localhost:3000"),
   NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
   PORT: z.string().transform(Number).default(3000),
   DATABASE_URL: z.string().url(),
   REDIS_URL: z.string().url().default("redis://localhost:6379"),
   JWT_SECRET: z.string().min(32).default("your-very-secure-access-secret-key-change-me"),
   JWT_REFRESH_SECRET: z.string().min(32).default("your-very-secure-refresh-secret-key-change-me"),
   AWS_ACCESS_KEY_ID: z.string(),
   AWS_SECRET_ACCESS_KEY: z.string(),
   AWS_REGION: z.string(),
   AWS_S3_BUCKET_NAME: z.string(),
   SMTP_USER: z.string().email(),
   SMTP_PASS: z.string().min(1),
   SMTP_FROM: z.string().email().optional(),

   // RevenueCat — both required; app will NOT start without them
   REVENUECAT_SECRET_API_KEY: z.string().min(1),
   REVENUECAT_WEBHOOK_SECRET: z.string().min(1),

   // ZEGOCLOUD — populate from https://console.zegocloud.com/
   ZEGO_APP_ID: z.coerce.number().default(0),
   ZEGO_APP_SIGN: z.string().default(""),
   ZEGO_SERVER_SECRET: z.string().default(""),

   // Google Maps
   GOOGLE_PLACES_API_KEY: z.string().default("random-dev-key"),

   // CORS — comma-separated allowed origins for production (e.g. https://app.example.com)
   // Leave empty in development to allow all origins
   ALLOWED_ORIGINS: z.string().default(""),

   // Google Auth
   GOOGLE_CLIENT_ID: z.string().default("default-google-client-id"),
   GOOGLE_CLIENT_SECRET: z.string().default("default-google-client-secret"),
});

const _env = envSchema.safeParse(process.env);

if (!_env.success) {
   console.error("❌ Invalid environment variables:", _env.error.format());
   process.exit(1);
}

export const env = _env.data;
export default env;
