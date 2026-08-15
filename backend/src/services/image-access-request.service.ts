import { IImageAccessRequestRepository } from "@/interfaces/repositories/image-access-request.repository.interface";
import { IImageAccessRequestService } from "@/interfaces/services/image-access-request.service.interface";
import { IS3Service } from "@/interfaces/services/s3.service.interface";
import { notificationService } from "@/composer/composer";
import { NotificationType } from "@/constants/notificationTypes";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { ImageAccessRequest, ImageAccessStatus } from "@prisma/client";
import { ImageAccessRequestResponseDto } from "@/dtos/image-access-request.dto";
import logger from "@/utils/logger";
import { prisma } from "@/config/prisma";

export class ImageAccessRequestService implements IImageAccessRequestService {
   constructor(
      private readonly requestRepository: IImageAccessRequestRepository,
      private readonly s3Service: IS3Service
   ) {}

   async requestAccess(requesterUserId: number, targetUserId: number): Promise<ImageAccessRequest> {
      if (requesterUserId === targetUserId) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Cannot request access to your own images");
      }

      const existingRequest = await this.requestRepository.findByOwnerAndRequester(targetUserId, requesterUserId);

      if (existingRequest) {
         if (existingRequest.status === ImageAccessStatus.PENDING || existingRequest.status === ImageAccessStatus.APPROVED) {
            return existingRequest;
         }
      }

      const created = await this.requestRepository.createOrUpdatePendingRequest(targetUserId, requesterUserId);

      this.notifyImageAccessRequested(requesterUserId, targetUserId).catch((err) => {
         logger.error("Failed to send image access requested notification:", err);
      });

      return created;
   }

   async getReceivedRequests(ownerUserId: number): Promise<ImageAccessRequestResponseDto[]> {
      const requests = await this.requestRepository.findReceivedRequests(ownerUserId);
      return Promise.all(
         requests.map(async (req) => {
            const profile = req.requester?.profile;
            let imageUrl = null;
            let imageId = null;
            if (profile?.images) {
               const primaryImg = profile.images.find((img) => img.isPrimary) || profile.images[0];
               if (primaryImg) {
                  imageId = primaryImg.id;
                  imageUrl = await this.s3Service.getPresignedUrl(primaryImg.imageUrl);
               }
            }
            return {
               id: req.id,
               ownerUserId: req.ownerUserId,
               requesterUserId: req.requesterUserId,
               status: req.status,
               requestedAt: req.requestedAt,
               respondedAt: req.respondedAt,
               requesterProfile: profile
                  ? {
                       name: profile.name,
                       age: profile.dateOfBirth ? this.calculateAge(profile.dateOfBirth) : null,
                       imageId,
                       imageUrl,
                       presignedImageUrl: imageUrl,
                    }
                  : null,
            };
         })
      );
   }

   async getSentRequests(requesterUserId: number): Promise<ImageAccessRequestResponseDto[]> {
      const requests = await this.requestRepository.findSentRequests(requesterUserId);
      return Promise.all(
         requests.map(async (req) => {
            const profile = req.owner?.profile;
            let imageUrl = null;
            let imageId = null;
            if (profile?.images) {
               const primaryImg = profile.images.find((img) => img.isPrimary) || profile.images[0];
               if (primaryImg) {
                  imageId = primaryImg.id;
                  imageUrl = await this.s3Service.getPresignedUrl(primaryImg.imageUrl);
               }
            }
            return {
               id: req.id,
               ownerUserId: req.ownerUserId,
               requesterUserId: req.requesterUserId,
               status: req.status,
               requestedAt: req.requestedAt,
               respondedAt: req.respondedAt,
               ownerProfile: profile
                  ? {
                       name: profile.name,
                       age: profile.dateOfBirth ? this.calculateAge(profile.dateOfBirth) : null,
                       imageId,
                       imageUrl,
                       presignedImageUrl: imageUrl,
                    }
                  : null,
            };
         })
      );
   }

   private calculateAge(dateOfBirth: Date): number {
      const today = new Date();
      const birthDate = new Date(dateOfBirth);
      let age = today.getFullYear() - birthDate.getFullYear();
      const m = today.getMonth() - birthDate.getMonth();
      if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
         age--;
      }
      return age;
   }

   async approveRequest(ownerUserId: number, requestId: number): Promise<ImageAccessRequest> {
      const request = await this.getRequestOrThrow(requestId);

      if (request.ownerUserId !== ownerUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Only the owner can approve the request");
      }

      if (request.status !== ImageAccessStatus.PENDING) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Can only approve pending requests");
      }

      const updated = await this.requestRepository.updateStatus(requestId, ImageAccessStatus.APPROVED);

      this.notifyImageAccessGranted(ownerUserId, request.requesterUserId).catch((err) => {
         logger.error("Failed to send image access granted notification:", err);
      });

      return updated;
   }

   private async notifyImageAccessRequested(requesterUserId: number, ownerUserId: number): Promise<void> {
      const requesterProfile = await prisma.profile.findFirst({
         where: { userId: requesterUserId },
         select: { name: true, id: true },
      });
      const name = requesterProfile?.name || "Someone";
      await notificationService.sendToUser({
         userId: ownerUserId,
         type: NotificationType.IMAGE_ACCESS_REQUESTED,
         title: "Image Access Requested",
         body: `${name} requested access to view your photos.`,
         data: {
            type: NotificationType.IMAGE_ACCESS_REQUESTED,
            profileId: String(requesterProfile?.id || requesterUserId),
         },
      });
   }

   private async notifyImageAccessGranted(ownerUserId: number, requesterUserId: number): Promise<void> {
      const ownerProfile = await prisma.profile.findFirst({
         where: { userId: ownerUserId },
         select: { name: true, id: true },
      });
      const name = ownerProfile?.name || "Someone";
      await notificationService.sendToUser({
         userId: requesterUserId,
         type: NotificationType.IMAGE_ACCESS_GRANTED,
         title: "Photo Access Granted! 📸",
         body: `${name} granted you access to view their photos.`,
         data: {
            type: NotificationType.IMAGE_ACCESS_GRANTED,
            profileId: String(ownerProfile?.id || ownerUserId),
         },
      });
   }

   async rejectRequest(ownerUserId: number, requestId: number): Promise<ImageAccessRequest> {
      const request = await this.getRequestOrThrow(requestId);

      if (request.ownerUserId !== ownerUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Only the owner can reject the request");
      }

      if (request.status !== ImageAccessStatus.PENDING) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Can only reject pending requests");
      }

      return this.requestRepository.updateStatus(requestId, ImageAccessStatus.REJECTED);
   }

   async cancelRequest(requesterUserId: number, requestId: number): Promise<ImageAccessRequest> {
      const request = await this.getRequestOrThrow(requestId);

      if (request.requesterUserId !== requesterUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Only the requester can cancel the request");
      }

      if (request.status !== ImageAccessStatus.PENDING) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Can only cancel pending requests");
      }

      return this.requestRepository.updateStatus(requestId, ImageAccessStatus.CANCELLED);
   }

   async revokeRequest(revokerUserId: number, requestId: number): Promise<ImageAccessRequest> {
      const request = await this.getRequestOrThrow(requestId);

      if (request.ownerUserId !== revokerUserId && request.requesterUserId !== revokerUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Only the owner or requester can revoke the request");
      }

      if (request.status !== ImageAccessStatus.APPROVED) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Can only revoke approved requests");
      }

      return this.requestRepository.updateStatus(requestId, ImageAccessStatus.REVOKED, revokerUserId);
   }

   async getApprovedAccessesForViewer(viewerUserId: number, ownerUserIds: number[]): Promise<ImageAccessRequest[]> {
      return this.requestRepository.findApprovedAccessesForViewer({ viewerUserId, ownerUserIds });
   }

   private async getRequestOrThrow(requestId: number): Promise<ImageAccessRequest> {
      const request = await this.requestRepository.findById(requestId);
      if (!request) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Image access request not found");
      }
      return request;
   }
}
