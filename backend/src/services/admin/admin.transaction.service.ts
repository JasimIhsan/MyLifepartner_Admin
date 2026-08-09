import { TransactionHistoryRepository } from "@/repositories/transaction-history.repository";
import { IAdminTransactionQuery, AdminTransaction } from "@/interfaces/repositories/transaction-history.repository.interface";

export class AdminTransactionService {
   private transactionRepository: TransactionHistoryRepository;

   constructor() {
      this.transactionRepository = new TransactionHistoryRepository();
   }

   public async getTransactions(query: IAdminTransactionQuery): Promise<{ transactions: AdminTransaction[]; total: number }> {
      return this.transactionRepository.getAdminTransactions(query);
   }
}
