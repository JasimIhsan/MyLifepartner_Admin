import { MessageType } from "@/interfaces/services/chat.service.interface";
import { IUserFeatureService } from "@/interfaces/services/user.feature.service.interface";
import { ChatService } from "@/services/chat.service";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class ChatController {
   constructor(
      private readonly chatService: ChatService
   ) {}

   /**
    * @route POST /api/v1/user/chat/messages
    * @purpose Sends a new chat message to another user.
    */
   public sendMessage = asyncHandler(async (req: Request, res: Response) => {
      const senderId = this.getAuthenticatedUserId(req);
      const receiverId = this.getRequiredPositiveNumber(req.body.receiverId, "Receiver ID is required");
      const content = this.getRequiredString(req.body.content, "Message content is required");
      const messageType = this.getMessageType(req.body.messageType);
      const zegoMessageId = this.getOptionalString(req.body.zegoMessageId);

      const message = await this.chatService.sendMessage(senderId, receiverId, content, messageType, zegoMessageId);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, message, "Message sent successfully"));
   });

   /**
    * @route GET /api/v1/user/chat/conversations
    * @purpose Fetches all chat conversations of the authenticated user.
    */
   public getConversations = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const conversations = await this.chatService.getConversations(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, conversations, "Conversations retrieved successfully"));
   });

   /**
    * @route GET /api/v1/user/chat/conversations/:conversationId/messages
    * @purpose Fetches paginated messages from a conversation.
    */
   public getMessages = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);
      const conversationId = this.getRequiredPositiveNumber(req.params.conversationId, "Invalid conversation ID");

      const page = this.getPaginationNumber(req.query.page, 1, 1, 100000);
      const limit = this.getPaginationNumber(req.query.limit, 50, 1, 100);

      const result = await this.chatService.getMessages(userId, conversationId, page, limit);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Messages retrieved successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: Request): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Extracts and validates required string input.
    */
   private getRequiredString(value: unknown, errorMessage: string): string {
      if (typeof value !== "string" || value.trim().length === 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return value.trim();
   }

   /**
    * Extracts optional string input.
    */
   private getOptionalString(value: unknown): string | undefined {
      if (value === undefined || value === null) {
         return undefined;
      }

      if (typeof value !== "string") {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid request value");
      }

      const trimmedValue = value.trim();

      return trimmedValue.length > 0 ? trimmedValue : undefined;
   }

   /**
    * Extracts and validates message type.
    */
   private getMessageType(value: unknown): MessageType | undefined {
      const messageType = this.getOptionalString(value);

      if (!messageType) {
         return undefined;
      }

      const validMessageTypes = Object.values(MessageType) as string[];

      if (!validMessageTypes.includes(messageType)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, `Message type must be one of: ${validMessageTypes.join(", ")}`);
      }

      return messageType as MessageType;
   }

   /**
    * Extracts and validates a positive number.
    */
   private getRequiredPositiveNumber(value: unknown, errorMessage: string): number {
      const numberValue = Number(value);

      if (!Number.isInteger(numberValue) || numberValue <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, errorMessage);
      }

      return numberValue;
   }

   /**
    * Extracts and validates pagination values.
    */
   private getPaginationNumber(value: unknown, defaultValue: number, minValue: number, maxValue: number): number {
      if (value === undefined || value === null || value === "") {
         return defaultValue;
      }

      const numberValue = Number(value);

      if (!Number.isInteger(numberValue) || numberValue < minValue) {
         return defaultValue;
      }

      return Math.min(numberValue, maxValue);
   }

}
