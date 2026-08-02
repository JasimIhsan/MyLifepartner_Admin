import { ITransactionHistoryRepository, TransactionHistoryWithPlan } from "@/interfaces/repositories/transaction-history.repository.interface";
import { ITransactionHistoryService } from "@/interfaces/services/transaction-history.service.interface";

export class TransactionHistoryService implements ITransactionHistoryService {
   constructor(
      private readonly transactionHistoryRepository: ITransactionHistoryRepository
   ) {}

   async getUserTransactions(userId: number): Promise<TransactionHistoryWithPlan[]> {
      return this.transactionHistoryRepository.getUserTransactions(userId);
   }
}
