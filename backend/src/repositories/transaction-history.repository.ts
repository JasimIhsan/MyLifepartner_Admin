import prisma from "@/config/prisma";
import { Prisma, TransactionHistory } from "@prisma/client";
import { ITransactionHistoryRepository, TransactionHistoryWithPlan } from "@/interfaces/repositories/transaction-history.repository.interface";

export class TransactionHistoryRepository implements ITransactionHistoryRepository {
   async createTransaction(data: Prisma.TransactionHistoryCreateInput): Promise<TransactionHistory> {
      return prisma.transactionHistory.create({
         data,
      });
   }

   async getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]> {
      return prisma.transactionHistory.findMany({
         where: { userId },
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
