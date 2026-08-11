import { Request, Response } from "express";
import { HTTP_STATUS } from "@/utils/constants";
import { asyncHandler } from "@/utils/asyncHandler";
import { ApiResponse } from "@/utils/ApiResponse";
import { AdminTransactionService } from "@/services/admin/admin.transaction.service";

class AdminTransactionController {
   private adminTransactionService: AdminTransactionService;

   constructor() {
      this.adminTransactionService = new AdminTransactionService();
   }

   public getTransactions = asyncHandler(async (req: Request, res: Response) => {
      const page = parseInt(req.query.page as string) || 1;
      const limit = parseInt(req.query.limit as string) || 10;
      const search = req.query.search as string;
      const status = req.query.status as string;
      const startDate = req.query.startDate as string;
      const endDate = req.query.endDate as string;

      const { transactions, total } = await this.adminTransactionService.getTransactions({
         page,
         limit,
         search,
         status,
         startDate,
         endDate,
      });

      return res.status(HTTP_STATUS.OK).json(
         new ApiResponse(
            HTTP_STATUS.OK,
            { transactions, total, page, limit },
            "Transactions retrieved successfully",
         )
      );
   });
}

export const adminTransactionController = new AdminTransactionController();
