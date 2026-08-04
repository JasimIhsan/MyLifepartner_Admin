import prisma from "../config/prisma";

export class NotificationRepository {
  public async createNotification(data: {
    userId: number;
    type: string;
    title: string;
    body: string;
    data?: any;
  }) {
    return prisma.notification.create({
      data: {
        userId: data.userId,
        type: data.type,
        title: data.title,
        body: data.body,
        data: data.data ?? null,
      },
    });
  }

  public async getNotificationsForUser(userId: number, page: number = 1, limit: number = 20) {
    const skip = (page - 1) * limit;

    const [items, total, unreadCount] = await Promise.all([
      prisma.notification.findMany({
        where: { userId },
        orderBy: { createdAt: "desc" },
        skip,
        take: limit,
      }),
      prisma.notification.count({
        where: { userId },
      }),
      prisma.notification.count({
        where: { userId, isRead: false },
      }),
    ]);

    return {
      items,
      total,
      unreadCount,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  public async markAllAsRead(userId: number) {
    return prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  public async markAsRead(userId: number, notificationId: number) {
    return prisma.notification.updateMany({
      where: { id: notificationId, userId },
      data: {
        isRead: true,
        readAt: new Date(),
      },
    });
  }

  public async getUnreadCount(userId: number): Promise<number> {
    return prisma.notification.count({
      where: { userId, isRead: false },
    });
  }
}
