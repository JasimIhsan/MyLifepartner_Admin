import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
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
});

const _env = envSchema.safeParse(process.env);

if (!_env.success) {
   console.error("❌ Invalid environment variables:", _env.error.format());
   process.exit(1);
}

export const env = _env.data;
export default env;
