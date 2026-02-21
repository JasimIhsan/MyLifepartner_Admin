import env from "@/config/env";
import { S3Client } from "@aws-sdk/client-s3";

// Initialize S3 Client
// Credentials should be picked up from env if available, or we pass them directly
export const s3Client = new S3Client({
   region: env.AWS_REGION || "ap-south-1",
   credentials: {
      accessKeyId: env.AWS_ACCESS_KEY_ID || "",
      secretAccessKey: env.AWS_SECRET_ACCESS_KEY || "",
   },
});
