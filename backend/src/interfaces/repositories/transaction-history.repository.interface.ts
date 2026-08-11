import { Prisma, TransactionHistory } from "@prisma/client";

export type TransactionHistoryWithPlan = TransactionHistory & {
   plan: {
      name: string;
      price: number;
   } | null;
};

export type AdminTransaction = TransactionHistory & {
   user: {
      email: string;
      profile: {
         name: string | null;
      } | null;
   };
   plan: {
      name: string;
   } | null;
};

export interface IAdminTransactionQuery {
   page: number;
   limit: number;
   search?: string;
   status?: string;
   startDate?: string;
   endDate?: string;
}

export interface ITransactionHistoryRepository {
   createTransaction(data: Prisma.TransactionHistoryCreateInput): Promise<TransactionHistory>;
   getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]>;
   getAdminTransactions(query: IAdminTransactionQuery): Promise<{ transactions: AdminTransaction[]; total: number }>;
}
