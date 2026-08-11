import prisma from "../config/prisma";

export class NotificationRepository {
   public async createNotification(data: { userId: number; type: string; title: string; body: string; data?: any }) {
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

   private mapCategoryToTypes(category?: string): string[] | undefined {
      switch (category) {
         case "Messages":
            return ["NEW_MESSAGE"];
         case "Subscriptions":
            return ["SUBSCRIPTION_SUCCESS", "SUBSCRIPTION_EXPIRING", "PAYMENT_FAILED"];
         case "Alerts":
            return ["NEW_LIKE", "NEW_MATCH", "INTEREST_ACCEPTED", "MISSED_CALL", "IMAGE_ACCESS_REQUESTED", "IMAGE_ACCESS_GRANTED"];
         case "System":
            return ["PROFILE_APPROVED", "PROFILE_REJECTED"];
         default:
            return undefined; // All notifications
      }
   }

   public async getNotificationsForUser(userId: number, page: number = 1, limit: number = 20, category?: string) {
      const skip = (page - 1) * limit;
      const types = this.mapCategoryToTypes(category);

      const whereClause: any = { userId };
      if (types) {
         whereClause.type = { in: types };
      }

      const [items, total, unreadCount] = await Promise.all([
         prisma.notification.findMany({
            where: whereClause,
            orderBy: { createdAt: "desc" },
            skip,
            take: limit,
         }),
         prisma.notification.count({
            where: whereClause,
         }),
         // unreadCount should probably remain global or category-specific depending on how we use it,
         // but in the previous version, it was global. Let's keep it global for now.
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
