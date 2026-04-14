import { chatController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

router.post("/messages", chatController.sendMessage);
router.get("/conversations", chatController.getConversations);
router.get("/conversations/:conversationId/messages", chatController.getMessages);

export default router;
