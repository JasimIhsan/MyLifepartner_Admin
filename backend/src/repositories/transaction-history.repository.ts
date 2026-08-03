import prisma from "@/config/prisma";
import { ITransactionHistoryRepository, TransactionHistoryWithPlan } from "@/interfaces/repositories/transaction-history.repository.interface";
import { Prisma, TransactionHistory } from "@prisma/client";

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
}
