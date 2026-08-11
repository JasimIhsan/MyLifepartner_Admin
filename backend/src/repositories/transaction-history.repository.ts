import prisma from "@/config/prisma";
import { AdminTransaction, IAdminTransactionQuery, ITransactionHistoryRepository, TransactionHistoryWithPlan } from "@/interfaces/repositories/transaction-history.repository.interface";
import { Prisma, TransactionHistory, TransactionStatus } from "@prisma/client";

export class TransactionHistoryRepository implements ITransactionHistoryRepository {
   async createTransaction(data: Prisma.TransactionHistoryCreateInput): Promise<TransactionHistory> {
      return prisma.transactionHistory.create({
         data,
      });
   }

   async getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]> {
      return prisma.transactionHistory.findMany({
         where: {
            userId,
            status: { in: ["PAID", "RENEWAL"] },
         },
         orderBy: { createdAt: "desc" },
         include: {
            plan: {
               select: {
                  name: true,
                  price: true,
               },
            },
         },
      });
   }

   async getAdminTransactions(query: IAdminTransactionQuery): Promise<{ transactions: AdminTransaction[]; total: number }> {
      const { page, limit, search, status, startDate, endDate } = query;
      const skip = (page - 1) * limit;

      const where: Prisma.TransactionHistoryWhereInput = {};

      if (search) {
         where.OR = [{ user: { email: { contains: search, mode: "insensitive" } } }, { originalTransactionId: { contains: search, mode: "insensitive" } }];
      }

      if (status) {
         where.status = status as TransactionStatus;
      }

      if (startDate || endDate) {
         where.createdAt = {};
         if (startDate) {
            where.createdAt.gte = new Date(startDate);
         }
         if (endDate) {
            const end = new Date(endDate);
            end.setHours(23, 59, 59, 999);
            where.createdAt.lte = end;
         }
      }

      const [transactions, total] = await Promise.all([
         prisma.transactionHistory.findMany({
            where,
            skip,
            take: limit,
            orderBy: { createdAt: "desc" },
            include: {
               user: {
                  select: {
                     email: true,
                     profile: {
                        select: {
                           name: true,
                        },
                     },
                  },
               },
               plan: {
                  select: {
                     name: true,
                  },
               },
            },
         }),
         prisma.transactionHistory.count({ where }),
      ]);

      return { transactions: transactions as AdminTransaction[], total };
   }
}
