import { userBlockController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

router.post("/:userId", userBlockController.blockUser);
router.delete("/:userId", userBlockController.unblockUser);
router.get("/", userBlockController.getBlockedUsers);

export default router;
