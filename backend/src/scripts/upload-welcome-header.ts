import { PutObjectCommand } from "@aws-sdk/client-s3";
import fs from "fs";
import path from "path";
import env from "../config/env";
import { s3Client } from "../config/s3.config";
import logger from "../utils/logger";

async function main() {
   const filePath = path.join(__dirname, "../templates/otp/otp-header.png");

   if (!fs.existsSync(filePath)) {
      throw new Error(`File not found at ${filePath}`);
   }

   const fileBuffer = fs.readFileSync(filePath);

   const command = new PutObjectCommand({
      Bucket: env.AWS_S3_BUCKET_NAME,
      Key: "assets/email-headers/otp-header.png",
      Body: fileBuffer,
      ContentType: "image/png",
   });

   logger.info(`Uploading otp-header.png to S3 bucket: ${env.AWS_S3_BUCKET_NAME}`);
   logger.info("Target S3 Key: assets/email-headers/otp-header.png");

   await s3Client.send(command);

   logger.info("Successfully uploaded otp-header.png to S3!");
}

main().catch((err) => {
   logger.error("Error uploading otp-header.png:", err);
   process.exit(1);
});
