import { BlockRepository } from "../repositories/block.repository";
import { UserBlock } from "@prisma/client";

export class BlockService {
  constructor(private blockRepository: BlockRepository) {}

  async blockUser(blockerId: number, blockedId: number): Promise<UserBlock> {
    if (blockerId === blockedId) {
      throw new Error("Cannot block yourself");
    }
    return this.blockRepository.blockUser(blockerId, blockedId);
  }

  async unblockUser(blockerId: number, blockedId: number): Promise<boolean> {
    return this.blockRepository.unblockUser(blockerId, blockedId);
  }

  async getBlockedUsers(blockerId: number): Promise<any[]> {
    const blocks = await this.blockRepository.getBlockedUsers(blockerId);
    return blocks.map((block) => ({
      id: block.id,
      blockerId: block.blockerUserId,
      blockedId: block.blockedUserId,
      createdAt: block.createdAt,
      targetUser: {
        id: block.blocked.id,
        name: block.blocked.profile?.name,
        email: block.blocked.email,
        profile: block.blocked.profile,
      },
    }));
  }

  async getExcludedUserIds(userId: number): Promise<number[]> {
    return this.blockRepository.getExcludedUserIds(userId);
  }
}
