import prisma from "@/config/prisma";
import { MessageType } from "@prisma/client";

export class ChatRepository {
   async findOrCreateConversation(userOneId: number, userTwoId: number) {
      // Always store the smaller ID as userOneId for uniqueness
      const [smallId, bigId] = userOneId < userTwoId
         ? [userOneId, userTwoId]
         : [userTwoId, userOneId];

      const existing = await prisma.conversation.findUnique({
         where: { userOneId_userTwoId: { userOneId: smallId, userTwoId: bigId } },
      });

      if (existing) return existing;

      return prisma.conversation.create({
         data: { userOneId: smallId, userTwoId: bigId },
      });
   }

   async saveMessage(
      conversationId: number,
      senderId: number,
      content: string,
      messageType: MessageType = "TEXT",
      zegoMessageId?: string,
   ) {
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

   async getMessages(
      conversationId: number,
      page: number = 1,
      limit: number = 50,
   ) {
      const skip = (page - 1) * limit;

      const [messages, total] = await Promise.all([
         prisma.chatMessage.findMany({
            where: { conversationId },
            orderBy: { createdAt: "desc" },
            skip,
            take: limit,
            include: {
               sender: {
                  select: {
                     id: true,
                     profile: { select: { name: true } },
                  },
               },
            },
         }),
         prisma.chatMessage.count({ where: { conversationId } }),
      ]);

      return { messages: messages.reverse(), total, page, limit };
   }

   async getConversations(userId: number) {
      return prisma.conversation.findMany({
         where: {
            OR: [{ userOneId: userId }, { userTwoId: userId }],
         },
         include: {
            userOne: {
               select: {
                  id: true,
                  profile: {
                     select: {
                        name: true,
                        images: {
                           where: { isPrimary: true },
                           take: 1,
                           select: { imageUrl: true },
                        },
                     },
                  },
               },
            },
            userTwo: {
               select: {
                  id: true,
                  profile: {
                     select: {
                        name: true,
                        images: {
                           where: { isPrimary: true },
                           take: 1,
                           select: { imageUrl: true },
                        },
                     },
                  },
               },
            },
            messages: {
               orderBy: { createdAt: "desc" },
               take: 1,
               select: { content: true, createdAt: true, senderId: true },
            },
         },
         orderBy: { updatedAt: "desc" },
      });
   }

   async isUserInConversation(userId: number, conversationId: number): Promise<boolean> {
      const convo = await prisma.conversation.findFirst({
         where: {
            id: conversationId,
            OR: [{ userOneId: userId }, { userTwoId: userId }],
         },
      });
      return !!convo;
   }
}
