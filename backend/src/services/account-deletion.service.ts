import prisma from "@/config/prisma";
import crypto from "crypto";
import { ZegoService } from "./zego.service";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { S3Service } from "./s3.service";
import { ReportService } from "./report.service";
import { ApiError } from "@/utils/ApiError";

export class AccountDeletionService {
   constructor(
      private readonly emailService: IEmailService,
      private readonly s3Service: S3Service,
      private readonly reportService: ReportService
   ) {}

   /**
    * Executes the full account deletion process for a user, enforcing all GDPR and 
    * privacy data retention policies.
    * 
    * @param userId The ID of the user to delete
    */
   async processAccountDeletion(userId: number): Promise<void> {
      // 1. Fetch user data before deletion
      const user = await prisma.user.findUnique({
         where: { id: userId },
         include: { profile: { include: { images: true } }, privacySettings: true },
      });

      if (!user || user.deleteRequestStatus !== "PENDING") {
         throw new ApiError(400, "Invalid or already processed deletion request");
      }

      const hasUnresolvedReports = await this.reportService.hasUnresolvedReportsAgainstUser(userId);

      if (hasUnresolvedReports) {
         throw new ApiError(400, "Cannot approve deletion. This user has unresolved reports that must be verified first.");
      }

      // 2. Send Account Deletion Confirmation Email
      if (user.email && !user.email.startsWith("deleted_")) {
         await this.emailService.sendModerationEmail(
            user.email,
            user.profile?.name || "User",
            "Account Deleted Successfully",
            "Your account and all associated personal data have been permanently deleted from Life Partner Again according to your request."
         ).catch(err => console.error(`Failed to send account deletion email to ${user.email}`, err));
      }

      const anonymizedEmail = `deleted_${userId}_${crypto.randomUUID()}@premiumglobalcorp.com`;

      await prisma.$transaction(async (tx) => {
         // 3. Anonymize user
         await tx.user.update({
            where: { id: userId },
            data: {
               email: anonymizedEmail,
               password: null,
               isDeleted: true,
               deleteRequestStatus: "APPROVED",
            },
         });

         // 4. Anonymize profile & delete personal answers/preferences
         if (user.profile) {
            await tx.profile.update({
               where: { userId },
               data: {
                  name: "Deleted User",
                  dateOfBirth: null,
                  city: null,
                  state: null,
                  country: null,
                  highestEducation: null,
                  bio: null,
                  selfieUrl: null,
                  leftSelfieUrl: null,
                  rightSelfieUrl: null,
                  lastLocationLat: null,
                  lastLocationLng: null,
                  gender: null,
                  maritalStatus: null,
                  motherTongue: null,
                  childrenStatus: null,
                  drinkingHabit: null,
                  emotionalReadiness: null,
                  languages: [],
                  lookingFor: null,
                  relationshipTimeline: null,
                  smokingHabit: null,
               },
            });

            // Delete User Images
            if (user.profile.images.length > 0) {
               await tx.userImage.deleteMany({
                  where: { profileId: user.profile.id },
               });
            }

            // Delete User Answers
            await tx.userAnswer.deleteMany({
               where: { profileId: user.profile.id },
            });
         }

         // Delete Partner Preferences
         await tx.partnerPreference.deleteMany({
            where: { userId },
         });

         // 5. Clear privacy image
         if (user.privacySettings?.blurredImageUrl) {
            await tx.privacySettings.update({
               where: { userId },
               data: { blurredImageUrl: null },
            });
         }

         // 6. Delete device tokens and social accounts
         await tx.deviceToken.deleteMany({ where: { userId } });
         await tx.socialAccount.deleteMany({ where: { userId } });

         // 7. Chat Cascade Deletion (Delete conversations where BOTH users are deleted)
         const conversations = await tx.conversation.findMany({
            where: {
               OR: [
                  { userOneId: userId },
                  { userTwoId: userId }
               ]
            },
            include: { userOne: true, userTwo: true }
         });

         const conversationsToDelete = conversations.filter(c => 
            (c.userOneId === userId && c.userTwo.isDeleted) ||
            (c.userTwoId === userId && c.userOne.isDeleted)
         ).map(c => c.id);

         if (conversationsToDelete.length > 0) {
            await tx.chatMessage.deleteMany({
               where: { conversationId: { in: conversationsToDelete } }
            });
            await tx.conversation.deleteMany({
               where: { id: { in: conversationsToDelete } }
            });
         }
      });

      // Cleanup files from S3 asynchronously
      const filesToDelete = [];
      if (user.profile?.selfieUrl) filesToDelete.push(user.profile.selfieUrl);
      if (user.profile?.leftSelfieUrl) filesToDelete.push(user.profile.leftSelfieUrl);
      if (user.profile?.rightSelfieUrl) filesToDelete.push(user.profile.rightSelfieUrl);
      if (user.privacySettings?.blurredImageUrl) filesToDelete.push(user.privacySettings.blurredImageUrl);
      user.profile?.images.forEach((img) => filesToDelete.push(img.imageUrl));

      if (filesToDelete.length > 0) {
         filesToDelete.forEach((file) => {
            this.s3Service.deleteFromS3(file).catch((err: unknown) => {
               console.error(`Failed to delete file ${file} from S3 during account deletion`, err);
            });
         });
      }

      // Cleanup Zegocloud data asynchronously
      const zegoService = new ZegoService();
      zegoService.deleteUser(userId.toString()).catch((err: unknown) => {
         console.error(`Failed to delete user ${userId} from Zegocloud`, err);
      });
   }
}
