import { ChatService } from "@/services/chat.service";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

export class ChatController {
   constructor(private readonly chatService: ChatService) {}

   /**
    * POST /chat/messages
    * Body: { receiverId: number, content: string, messageType?: string, zegoMessageId?: string }
    */
   sendMessage = asyncHandler(async (req: Request, res: Response) => {
      const senderId = req.user!.id;
      const { receiverId, content, messageType, zegoMessageId } = req.body;

      if (!receiverId || !content) {
         return res.status(400).json(
            new ApiResponse(400, null, "receiverId and content are required"),
         );
      }

      const message = await this.chatService.sendMessage(
         senderId,
         receiverId,
         content,
         messageType,
         zegoMessageId,
      );

      res.status(201).json(
         new ApiResponse(201, message, "Message sent"),
      );
   });

   /**
    * GET /chat/conversations
    */
   getConversations = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id;
      const conversations = await this.chatService.getConversations(userId);
      res.status(200).json(
         new ApiResponse(200, conversations, "Conversations retrieved"),
      );
   });

   /**
    * GET /chat/conversations/:conversationId/messages?page=1&limit=50
    */
   getMessages = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user!.id;
      const conversationId = Number(req.params.conversationId);
      const page = Number(req.query.page) || 1;
      const limit = Math.min(Number(req.query.limit) || 50, 100);

      const result = await this.chatService.getMessages(
         userId,
         conversationId,
         page,
         limit,
      );

      res.status(200).json(
         new ApiResponse(200, result, "Messages retrieved"),
      );
   });
}
