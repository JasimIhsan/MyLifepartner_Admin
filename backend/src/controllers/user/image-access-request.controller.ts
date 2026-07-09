import { IImageAccessRequestService } from "@/interfaces/services/image-access-request.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";

export class ImageAccessRequestController {
   constructor(private readonly accessRequestService: IImageAccessRequestService) {}

   /**
    * @route POST /api/v1/user/profiles/:targetUserId/image-access/request
    * @purpose Requests image access to another user's profile.
    */
   public requestAccess = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const targetUserId = Number(req.params.targetUserId);

      if (!Number.isInteger(targetUserId) || targetUserId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid target user ID");
      }

      const request = await this.accessRequestService.requestAccess(authUserId, targetUserId);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, request, "Image access requested successfully"));
   });

   /**
    * @route GET /api/v1/user/image-access/received
    * @purpose Fetches received image access requests.
    */
   public getReceivedRequests = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);

      const requests = await this.accessRequestService.getReceivedRequests(authUserId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, requests, "Received requests fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/image-access/sent
    * @purpose Fetches sent image access requests.
    */
   public getSentRequests = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);

      const requests = await this.accessRequestService.getSentRequests(authUserId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, requests, "Sent requests fetched successfully"));
   });

   /**
    * @route PATCH /api/v1/user/image-access/:requestId/approve
    * @purpose Approves a pending image access request.
    */
   public approveRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const requestId = Number(req.params.requestId);

      this.validateRequestId(requestId);

      const request = await this.accessRequestService.approveRequest(authUserId, requestId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, request, "Image access request approved"));
   });

   /**
    * @route PATCH /api/v1/user/image-access/:requestId/reject
    * @purpose Rejects a pending image access request.
    */
   public rejectRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const requestId = Number(req.params.requestId);

      this.validateRequestId(requestId);

      const request = await this.accessRequestService.rejectRequest(authUserId, requestId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, request, "Image access request rejected"));
   });

   /**
    * @route PATCH /api/v1/user/image-access/:requestId/cancel
    * @purpose Cancels a pending sent image access request.
    */
   public cancelRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const requestId = Number(req.params.requestId);

      this.validateRequestId(requestId);

      const request = await this.accessRequestService.cancelRequest(authUserId, requestId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, request, "Image access request cancelled"));
   });

   /**
    * @route PATCH /api/v1/user/image-access/:requestId/revoke
    * @purpose Revokes an approved image access request.
    */
   public revokeRequest = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const requestId = Number(req.params.requestId);

      this.validateRequestId(requestId);

      const request = await this.accessRequestService.revokeRequest(authUserId, requestId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, request, "Image access revoked successfully"));
   });

   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);
      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }
      return userId;
   }

   private validateRequestId(requestId: number): void {
      if (!Number.isInteger(requestId) || requestId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid request ID");
      }
   }
}
