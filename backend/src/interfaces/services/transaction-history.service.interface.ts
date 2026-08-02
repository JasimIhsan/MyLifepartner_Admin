import { TransactionHistoryWithPlan } from "../repositories/transaction-history.repository.interface";

export interface ITransactionHistoryService {
   getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]>;
}
