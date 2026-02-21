import env from "@/config/env";
import { s3Client } from "@/config/s3.config";
import { DeleteObjectCommand, GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { v4 as uuidv4 } from "uuid";

class S3Service {
   /**
    * Uploads a file to AWS S3.
    * @param file The file object from Multer
    * @param folder The folder in S3 to upload to
    * @returns The public URL of the uploaded image
    */
   public async uploadToS3(file: Express.Multer.File, folder: string = "profile_images"): Promise<string> {
      if (!env.AWS_S3_BUCKET_NAME) {
         throw new Error("AWS_S3_BUCKET_NAME is not defined in environment variables.");
      }

      const fileExtension = file.originalname.split(".").pop();
      const fileName = `${folder}/${uuidv4()}.${fileExtension}`;

      const command = new PutObjectCommand({
         Bucket: env.AWS_S3_BUCKET_NAME,
         Key: fileName,
         Body: file.buffer,
         ContentType: file.mimetype,
         // Note: If you want files to be public, the bucket must allow public ACLs and you can uncomment the line below:
         // ACL: "public-read",
      });

      await s3Client.send(command);

      // Return the constructed S3 URL
      return `https://${env.AWS_S3_BUCKET_NAME}.s3.${env.AWS_REGION || "us-east-1"}.amazonaws.com/${fileName}`;
   }

   /**
    * Deletes a file from AWS S3 using its URL.
    * @param fileUrl The full URL of the file in S3
    */
   public async deleteFromS3(fileUrl: string): Promise<void> {
      if (!env.AWS_S3_BUCKET_NAME) return;

      try {
         const region = env.AWS_REGION || "us-east-1";
         const bucketUrl = `https://${env.AWS_S3_BUCKET_NAME}.s3.${region}.amazonaws.com/`;

         if (!fileUrl.startsWith(bucketUrl)) {
            console.warn("URL does not match S3 bucket URL, skipping deletion:", fileUrl);
            return;
         }

         const key = fileUrl.replace(bucketUrl, "");

         const command = new DeleteObjectCommand({
            Bucket: env.AWS_S3_BUCKET_NAME,
            Key: key,
         });

         await s3Client.send(command);
      } catch (error) {
         console.error("Error deleting file from S3:", error);
      }
   }

   /**
    * Generates a presigned URL for a given S3 object URL.
    * @param fileUrl The full URL of the file in S3
    * @param expiresIn Expiration time in seconds (default 1 hour)
    * @returns A presigned URL allowing temporary access to the file
    */
   public async getPresignedUrl(fileUrl: string, expiresIn: number = 3600): Promise<string> {
      if (!env.AWS_S3_BUCKET_NAME) {
         console.warn("AWS_S3_BUCKET_NAME is not defined. Returning original URL.");
         return fileUrl;
      }

      try {
         const region = env.AWS_REGION || "us-east-1";
         const bucketUrl = `https://${env.AWS_S3_BUCKET_NAME}.s3.${region}.amazonaws.com/`;

         // If it's not our S3 bucket URL, just return it (e.g., external URLs or already presigned)
         if (!fileUrl.startsWith(bucketUrl)) {
            return fileUrl;
         }

         const key = fileUrl.replace(bucketUrl, "");

         const command = new GetObjectCommand({
            Bucket: env.AWS_S3_BUCKET_NAME,
            Key: key,
         });

         const presignedUrl = await getSignedUrl(s3Client, command, { expiresIn });
         return presignedUrl;
      } catch (error) {
         console.error("Error generating presigned URL:", error);
         // Fallback to original URL if presigning fails
         return fileUrl;
      }
   }
}

export const s3Service = new S3Service();
