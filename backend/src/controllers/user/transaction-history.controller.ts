import { ITransactionHistoryService } from "@/interfaces/services/transaction-history.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class TransactionHistoryController {
   constructor(
      private readonly transactionHistoryService: ITransactionHistoryService
   ) {}

   /**
    * @route GET /api/v1/user/transactions
    * @purpose Fetches authenticated user's transaction history.
    */
   public getUserTransactions = asyncHandler(async (req: Request, res: Response) => {
      const userId = this.getAuthenticatedUserId(req);

      const transactions = await this.transactionHistoryService.getUserTransactions(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, transactions, "Transaction history retrieved successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: Request): number {
      const userId = Number(req.user?.id);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }
}
