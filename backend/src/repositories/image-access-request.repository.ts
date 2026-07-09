import { IImageAccessRequestRepository } from "@/interfaces/repositories/image-access-request.repository.interface";
import { ImageAccessRequest, ImageAccessStatus } from "@prisma/client";
import prisma from "@/config/prisma";

export class ImageAccessRequestRepository implements IImageAccessRequestRepository {
   async findByOwnerAndRequester(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest | null> {
      return prisma.imageAccessRequest.findUnique({
         where: {
            ownerUserId_requesterUserId: {
               ownerUserId,
               requesterUserId,
            },
         },
      });
   }

   async createOrUpdatePendingRequest(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest> {
      return prisma.imageAccessRequest.upsert({
         where: {
            ownerUserId_requesterUserId: {
               ownerUserId,
               requesterUserId,
            },
         },
         update: {
            status: ImageAccessStatus.PENDING,
            requestedAt: new Date(),
            respondedAt: null,
            revokedAt: null,
            revokedByUserId: null,
         },
         create: {
            ownerUserId,
            requesterUserId,
            status: ImageAccessStatus.PENDING,
            requestedAt: new Date(),
         },
      });
   }

   async findReceivedRequests(ownerUserId: number): Promise<ImageAccessRequest[]> {
      return prisma.imageAccessRequest.findMany({
         where: { ownerUserId },
         orderBy: { requestedAt: "desc" },
      });
   }

   async findSentRequests(requesterUserId: number): Promise<ImageAccessRequest[]> {
      return prisma.imageAccessRequest.findMany({
         where: { requesterUserId },
         orderBy: { requestedAt: "desc" },
      });
   }

   async findApprovedAccess(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest | null> {
      return prisma.imageAccessRequest.findFirst({
         where: {
            ownerUserId,
            requesterUserId,
            status: ImageAccessStatus.APPROVED,
         },
      });
   }

   async findApprovedAccessesForViewer(params: { viewerUserId: number; ownerUserIds: number[] }): Promise<ImageAccessRequest[]> {
      if (params.ownerUserIds.length === 0) return [];
      
      return prisma.imageAccessRequest.findMany({
         where: {
            requesterUserId: params.viewerUserId,
            ownerUserId: {
               in: params.ownerUserIds,
            },
            status: ImageAccessStatus.APPROVED,
         },
      });
   }

   async findById(requestId: number): Promise<ImageAccessRequest | null> {
      return prisma.imageAccessRequest.findUnique({
         where: { id: requestId },
      });
   }

   async updateStatus(requestId: number, status: ImageAccessStatus, revokedByUserId?: number): Promise<ImageAccessRequest> {
      const updateData: any = { status };
      
      if (status === ImageAccessStatus.APPROVED || status === ImageAccessStatus.REJECTED) {
         updateData.respondedAt = new Date();
      } else if (status === ImageAccessStatus.REVOKED) {
         updateData.revokedAt = new Date();
         updateData.revokedByUserId = revokedByUserId;
      }

      return prisma.imageAccessRequest.update({
         where: { id: requestId },
         data: updateData,
      });
   }
}
