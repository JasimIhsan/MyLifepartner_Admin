import { ImageAccessRequest } from "@prisma/client";
import { ImageAccessRequestResponseDto } from "@/dtos/image-access-request.dto";

export interface IImageAccessRequestService {
   requestAccess(requesterUserId: number, targetUserId: number): Promise<ImageAccessRequest>;
   getReceivedRequests(ownerUserId: number): Promise<ImageAccessRequestResponseDto[]>;
   getSentRequests(requesterUserId: number): Promise<ImageAccessRequestResponseDto[]>;
   approveRequest(ownerUserId: number, requestId: number): Promise<ImageAccessRequest>;
   rejectRequest(ownerUserId: number, requestId: number): Promise<ImageAccessRequest>;
   cancelRequest(requesterUserId: number, requestId: number): Promise<ImageAccessRequest>;
   revokeRequest(revokerUserId: number, requestId: number): Promise<ImageAccessRequest>;
   getApprovedAccessesForViewer(viewerUserId: number, ownerUserIds: number[]): Promise<ImageAccessRequest[]>;
}
