import { ImageAccessRequest, ImageAccessStatus } from "@prisma/client";

export interface IImageAccessRequestRepository {
   findByOwnerAndRequester(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest | null>;
   createOrUpdatePendingRequest(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest>;
   findReceivedRequests(ownerUserId: number): Promise<ImageAccessRequest[]>;
   findSentRequests(requesterUserId: number): Promise<ImageAccessRequest[]>;
   findApprovedAccess(ownerUserId: number, requesterUserId: number): Promise<ImageAccessRequest | null>;
   findApprovedAccessesForViewer(params: { viewerUserId: number; ownerUserIds: number[] }): Promise<ImageAccessRequest[]>;
   findById(requestId: number): Promise<ImageAccessRequest | null>;
   updateStatus(requestId: number, status: ImageAccessStatus, revokedByUserId?: number): Promise<ImageAccessRequest>;
}
