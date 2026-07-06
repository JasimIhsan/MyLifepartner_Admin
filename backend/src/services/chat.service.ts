import { ChatRepository } from "@/repositories/chat.repository";
import { ApiError } from "@/utils/ApiError";
import { ChatMessage, MessageType } from "@/interfaces/services/chat.service.interface";

const DEFAULT_MESSAGES_PAGE = 1;
const DEFAULT_MESSAGES_LIMIT = 50;

export class ChatService {
   constructor(private readonly chatRepository: ChatRepository) {}

   /**
    * Sends a chat message.
    *
    * @param senderId - Sender user ID.
    * @param receiverId - Receiver user ID.
    * @param content - Message content.
    * @param messageType - Message type.
    * @param zegoMessageId - Optional Zego message ID.
    * @returns Created chat message.
    */
   async sendMessage(senderId: number, receiverId: number, content: string, messageType: MessageType = MessageType.TEXT, zegoMessageId?: string): Promise<ChatMessage> {
      const messageContent = content.trim();

      if (!messageContent) {
         throw new ApiError(400, "Message content cannot be empty");
      }

      const conversation = await this.chatRepository.findOrCreateConversation(senderId, receiverId);

      return this.chatRepository.saveMessage(conversation.id, senderId, messageContent, messageType, zegoMessageId);
   }

   /**
    * Gets conversation messages.
    *
    * @param userId - User ID.
    * @param conversationId - Conversation ID.
    * @param page - Page number.
    * @param limit - Number of messages to fetch.
    * @returns Conversation messages with pagination details.
    */
   async getMessages(userId: number, conversationId: number, page: number = DEFAULT_MESSAGES_PAGE, limit: number = DEFAULT_MESSAGES_LIMIT) {
      await this.ensureUserCanAccessConversation(userId, conversationId);

      return this.chatRepository.getMessages(conversationId, page, limit);
   }

   /**
    * Gets user conversations.
    *
    * @param userId - User ID.
    * @returns User conversations.
    */
   async getConversations(userId: number) {
      return this.chatRepository.getConversations(userId);
   }

   /**
    * Checks whether user can access a conversation.
    *
    * @param userId - User ID.
    * @param conversationId - Conversation ID.
    * @returns Nothing.
    */
   private async ensureUserCanAccessConversation(userId: number, conversationId: number): Promise<void> {
      const hasAccess = await this.chatRepository.isUserInConversation(userId, conversationId);

      if (!hasAccess) {
         throw new ApiError(403, "You do not have access to this conversation");
      }
   }
}
