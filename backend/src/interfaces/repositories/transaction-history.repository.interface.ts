import { Prisma, TransactionHistory } from "@prisma/client";

export type TransactionHistoryWithPlan = TransactionHistory & {
   plan: {
      name: string;
      price: number;
   } | null;
};

export interface ITransactionHistoryRepository {
   createTransaction(data: Prisma.TransactionHistoryCreateInput): Promise<TransactionHistory>;
   getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]>;
}
