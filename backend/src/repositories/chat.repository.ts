import prisma from "@/config/prisma";
import { ChatMessage, Conversation, MessageType, Prisma } from "@prisma/client";

type PaginatedMessages = {
   messages: ChatMessage[];
   total: number;
   page: number;
   limit: number;
};

const conversationUserSelect = {
   id: true,
   profile: {
      select: {
         name: true,
         images: {
            where: {
               isPrimary: true,
            },
            take: 1,
            select: {
               imageUrl: true,
            },
         },
      },
   },
} satisfies Prisma.UserSelect;

export class ChatRepository {
   /**
    * Finds or creates a conversation between two users.
    *
    * @param userOneId - First user ID.
    * @param userTwoId - Second user ID.
    * @returns Existing or created conversation.
    */
   async findOrCreateConversation(userOneId: number, userTwoId: number): Promise<Conversation> {
      const [firstUserId, secondUserId] = this.sortUserIds(userOneId, userTwoId);

      return prisma.conversation.upsert({
         where: {
            userOneId_userTwoId: {
               userOneId: firstUserId,
               userTwoId: secondUserId,
            },
         },
         update: {},
         create: {
            userOneId: firstUserId,
            userTwoId: secondUserId,
         },
      });
   }

   /**
    * Saves a chat message.
    *
    * @param conversationId - Conversation ID.
    * @param senderId - Sender user ID.
    * @param content - Message content.
    * @param messageType - Message type.
    * @param zegoMessageId - Optional Zego message ID.
    * @returns Created chat message.
    */
   async saveMessage(conversationId: number, senderId: number, content: string, messageType: MessageType = MessageType.TEXT, zegoMessageId?: string): Promise<ChatMessage> {
      return prisma.chatMessage.create({
         data: {
            conversationId,
            senderId,
            content,
            messageType,
            zegoMessageId,
         },
      });
   }

   /**
    * Gets paginated conversation messages.
    *
    * @param conversationId - Conversation ID.
    * @param page - Page number.
    * @param limit - Number of messages to fetch.
    * @returns Messages with pagination details.
    */
   async getMessages(conversationId: number, page: number = 1, limit: number = 50): Promise<PaginatedMessages> {
      const skip = (page - 1) * limit;

      const [messages, total] = await prisma.$transaction([
         prisma.chatMessage.findMany({
            where: {
               conversationId,
            },
            orderBy: {
               createdAt: "desc",
            },
            skip,
            take: limit,
            include: {
               sender: {
                  select: {
                     id: true,
                     profile: {
                        select: {
                           name: true,
                        },
                     },
                  },
               },
            },
         }),
         prisma.chatMessage.count({
            where: {
               conversationId,
            },
         }),
      ]);

      return {
         messages: messages.reverse(),
         total,
         page,
         limit,
      };
   }

   /**
    * Gets conversations of a user.
    *
    * @param userId - User ID.
    * @returns User conversations.
    */
   async getConversations(userId: number) {
      return prisma.conversation.findMany({
         where: {
            OR: [
               {
                  userOneId: userId,
               },
               {
                  userTwoId: userId,
               },
            ],
         },
         include: {
            userOne: {
               select: conversationUserSelect,
            },
            userTwo: {
               select: conversationUserSelect,
            },
            messages: {
               orderBy: {
                  createdAt: "desc",
               },
               take: 1,
               select: {
                  content: true,
                  createdAt: true,
                  senderId: true,
               },
            },
         },
         orderBy: {
            updatedAt: "desc",
         },
      });
   }

   /**
    * Checks if a user belongs to a conversation.
    *
    * @param userId - User ID.
    * @param conversationId - Conversation ID.
    * @returns True if the user belongs to the conversation, otherwise false.
    */
   async isUserInConversation(userId: number, conversationId: number): Promise<boolean> {
      const conversation = await prisma.conversation.findFirst({
         where: {
            id: conversationId,
            OR: [
               {
                  userOneId: userId,
               },
               {
                  userTwoId: userId,
               },
            ],
         },
         select: {
            id: true,
         },
      });

      return Boolean(conversation);
   }

   /**
    * Sorts two user IDs.
    *
    * @param userOneId - First user ID.
    * @param userTwoId - Second user ID.
    * @returns Sorted user IDs.
    */
   private sortUserIds(userOneId: number, userTwoId: number): [number, number] {
      return userOneId < userTwoId ? [userOneId, userTwoId] : [userTwoId, userOneId];
   }
}
