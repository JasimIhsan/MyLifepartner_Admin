import { Router } from "express";
import { transactionHistoryController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";

const router = Router();

router.use(verifyJWT);

/**
 * @route GET /user/transactions
 * @desc Get user's transaction history
 * @access Private
 */
router.get("/", transactionHistoryController.getUserTransactions);

export default router;
