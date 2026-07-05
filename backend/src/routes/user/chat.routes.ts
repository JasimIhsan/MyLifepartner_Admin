import { chatController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

/**
 * @route   POST /api/v1/user/chat/messages
 * @desc    Send a new chat message to a user
 * @access  Private
 */
router.post("/messages", chatController.sendMessage);

/**
 * @route   GET /api/v1/user/chat/conversations
 * @desc    Get all chat conversations for the current user
 * @access  Private
 */
router.get("/conversations", chatController.getConversations);

/**
 * @route   GET /api/v1/user/chat/conversations/:conversationId/messages
 * @desc    Get messages inside a specific conversation
 * @access  Private
 */
router.get("/conversations/:conversationId/messages", chatController.getMessages);

export default router;
