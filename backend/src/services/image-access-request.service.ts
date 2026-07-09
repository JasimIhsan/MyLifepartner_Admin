import { IImageAccessRequestRepository } from "@/interfaces/repositories/image-access-request.repository.interface";
import { IImageAccessRequestService } from "@/interfaces/services/image-access-request.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { ImageAccessRequest, ImageAccessStatus } from "@prisma/client";

export class ImageAccessRequestService implements IImageAccessRequestService {
   constructor(
      private readonly requestRepository: IImageAccessRequestRepository
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

      return this.requestRepository.createOrUpdatePendingRequest(targetUserId, requesterUserId);
   }

   async getReceivedRequests(ownerUserId: number): Promise<ImageAccessRequest[]> {
      return this.requestRepository.findReceivedRequests(ownerUserId);
   }

   async getSentRequests(requesterUserId: number): Promise<ImageAccessRequest[]> {
      return this.requestRepository.findSentRequests(requesterUserId);
   }

   async approveRequest(ownerUserId: number, requestId: number): Promise<ImageAccessRequest> {
      const request = await this.getRequestOrThrow(requestId);

      if (request.ownerUserId !== ownerUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Only the owner can approve the request");
      }

      if (request.status !== ImageAccessStatus.PENDING) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Can only approve pending requests");
      }

      return this.requestRepository.updateStatus(requestId, ImageAccessStatus.APPROVED);
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
