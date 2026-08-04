import { PrismaClient, DevicePlatform } from '@prisma/client';
import prisma from '../config/prisma';

export class DeviceTokenService {
  /**
   * Upsert a device token for a user.
   */
  public async upsertToken(
    userId: number,
    token: string,
    platform: DevicePlatform,
    deviceId?: string
  ) {
    // If the token exists for another user (or same user), we just upsert it based on token uniqueness.
    // If it moved to another user, this will update the userId.
    return await prisma.deviceToken.upsert({
      where: { token },
      update: {
        userId,
        platform,
        deviceId,
        isActive: true,
        lastSeenAt: new Date(),
      },
      create: {
        userId,
        token,
        platform,
        deviceId,
        isActive: true,
      },
    });
  }

  /**
   * Deactivate a specific token (e.g. on logout).
   */
  public async deactivateToken(userId: number, token: string) {
    const existing = await prisma.deviceToken.findUnique({ where: { token } });
    if (existing && existing.userId === userId) {
      return await prisma.deviceToken.update({
        where: { token },
        data: { isActive: false },
      });
    }
    return null;
  }

  /**
   * Remove invalid token (e.g., FCM tells us it's unregistered).
   */
  public async removeInvalidToken(token: string) {
    return await prisma.deviceToken.delete({
      where: { token },
    }).catch(() => null); // Ignore if it doesn't exist
  }

  /**
   * Get all active tokens for a user.
   */
  public async getActiveTokensForUser(userId: number) {
    return await prisma.deviceToken.findMany({
      where: {
        userId,
        isActive: true,
      },
    });
  }
}

export const deviceTokenService = new DeviceTokenService();
