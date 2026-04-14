import { ChatRepository } from "@/repositories/chat.repository";
import { ApiError } from "@/utils/ApiError";
import { MessageType } from "@prisma/client";

export class ChatService {
   constructor(private readonly chatRepository: ChatRepository) {}

   async sendMessage(
      senderId: number,
      receiverId: number,
      content: string,
      messageType: MessageType = "TEXT",
      zegoMessageId?: string,
   ) {
      if (!content || content.trim().length === 0) {
         throw new ApiError(400, "Message content cannot be empty");
      }

      const conversation = await this.chatRepository.findOrCreateConversation(
         senderId,
         receiverId,
      );

      return this.chatRepository.saveMessage(
         conversation.id,
         senderId,
         content.trim(),
         messageType,
         zegoMessageId,
      );
   }

   async getMessages(userId: number, conversationId: number, page = 1, limit = 50) {
      const hasAccess = await this.chatRepository.isUserInConversation(
         userId,
         conversationId,
      );
      if (!hasAccess) {
         throw new ApiError(403, "You do not have access to this conversation");
      }

      return this.chatRepository.getMessages(conversationId, page, limit);
   }

   async getConversations(userId: number) {
      return this.chatRepository.getConversations(userId);
   }
}
