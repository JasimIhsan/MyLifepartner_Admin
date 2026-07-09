import { prisma } from "../config/prisma";
import { S3Service } from "../services/s3.service";
import { ImageProcessorService } from "../services/image-processor.service";

const s3Service = new S3Service();
const imageProcessorService = new ImageProcessorService();

async function getBufferFromUrl(url: string): Promise<Buffer> {
   const response = await fetch(url);
   const arrayBuffer = await response.arrayBuffer();
   return Buffer.from(arrayBuffer);
}

async function backfillBlurredImages() {
   try {
      console.log("Starting backfill process for blurred images...");

      // Get all profiles that have a primary image
      const profiles = await prisma.profile.findMany({
         include: {
            images: {
               where: { isPrimary: true },
               take: 1,
            },
            user: {
               include: {
                  privacySettings: true,
               },
            },
         },
      });

      // Filter to all profiles that have a primary image
      const profilesToBackfill = profiles.filter(
         (p) => p.images.length > 0
      );

      console.log(`Found ${profilesToBackfill.length} profiles to backfill.`);

      for (const profile of profilesToBackfill) {
         const primaryImage = profile.images[0];
         console.log(`Processing profile ID ${profile.id} (user ${profile.userId})...`);

         try {
            const originalPresignedUrl = await s3Service.getPresignedUrl(primaryImage.imageUrl);
            const originalBuffer = await getBufferFromUrl(originalPresignedUrl);

            const pseudoFile = { buffer: originalBuffer } as Express.Multer.File;
            const blurredBuffer = await imageProcessorService.createBlurredImageBuffer(pseudoFile);

            const blurredS3Url = await s3Service.uploadBufferToS3({
               buffer: blurredBuffer,
               folder: `${profile.userId}/profile/blurred`,
               extension: "jpg",
               contentType: "image/jpeg",
            });

            // Delete old blurred image if it exists to prevent S3 object leakage
            if (profile.user.privacySettings?.blurredImageUrl) {
               try {
                  await s3Service.deleteFromS3(profile.user.privacySettings.blurredImageUrl);
                  console.log(`Deleted old blurred image for user ${profile.userId}`);
               } catch (deleteError) {
                  console.error(`Failed to delete old blurred image for user ${profile.userId}:`, deleteError);
               }
            }

            await prisma.privacySettings.upsert({
               where: { userId: profile.userId },
               update: { blurredImageUrl: blurredS3Url },
               create: { userId: profile.userId, blurredImageUrl: blurredS3Url },
            });

            console.log(`Successfully backfilled profile ID ${profile.id}`);
         } catch (error) {
            console.error(`Error processing profile ID ${profile.id}:`, error);
         }
      }

      console.log("Backfill process completed.");
   } catch (error) {
      console.error("Backfill process failed:", error);
   } finally {
      await prisma.$disconnect();
   }
}

backfillBlurredImages();
