import env from "@/config/env";
import { S3Client } from "@aws-sdk/client-s3";

const AWS_REGION = env.AWS_REGION ?? "ap-south-1";

if (!env.AWS_ACCESS_KEY_ID) {
   throw new Error("AWS_ACCESS_KEY_ID is missing in environment variables.");
}

if (!env.AWS_SECRET_ACCESS_KEY) {
   throw new Error("AWS_SECRET_ACCESS_KEY is missing in environment variables.");
}

export const s3Client = new S3Client({
   region: AWS_REGION,
   credentials: {
      accessKeyId: env.AWS_ACCESS_KEY_ID,
      secretAccessKey: env.AWS_SECRET_ACCESS_KEY,
   },
});
