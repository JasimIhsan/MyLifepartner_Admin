import { Router } from "express";
import { adminTransactionController } from "@/controllers/admin/admin.transaction.controller";

const router = Router();

router.get("/", adminTransactionController.getTransactions);

export default router;
