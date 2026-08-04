import { UserBlock } from "@prisma/client";
import prisma from "../config/prisma";

export class BlockRepository {
   async blockUser(blockerId: number, blockedId: number): Promise<UserBlock> {
      return prisma.userBlock.upsert({
         where: {
            blockerUserId_blockedUserId: {
               blockerUserId: blockerId,
               blockedUserId: blockedId,
            },
         },
         update: {},
         create: {
            blockerUserId: blockerId,
            blockedUserId: blockedId,
         },
      });
   }

   async unblockUser(blockerId: number, blockedId: number): Promise<boolean> {
      const result = await prisma.userBlock.deleteMany({
         where: {
            blockerUserId: blockerId,
            blockedUserId: blockedId,
         },
      });
      return result.count > 0;
   }

   async getBlockedUsers(blockerId: number): Promise<any[]> {
      return prisma.userBlock.findMany({
         where: {
            blockerUserId: blockerId,
         },
         include: {
            blocked: {
               include: {
                  profile: true,
               },
            },
         },
         orderBy: {
            createdAt: "desc",
         },
      });
   }

   async getExcludedUserIds(userId: number): Promise<number[]> {
      const blocks = await prisma.userBlock.findMany({
         where: {
            OR: [{ blockerUserId: userId }, { blockedUserId: userId }],
         },
         select: {
            blockerUserId: true,
            blockedUserId: true,
         },
      });

      const excludedIds = new Set<number>();
      for (const block of blocks) {
         if (block.blockerUserId === userId) {
            excludedIds.add(block.blockedUserId);
         } else {
            excludedIds.add(block.blockerUserId);
         }
      }

      return Array.from(excludedIds);
   }
}
