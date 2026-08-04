import { Router } from 'express';
import { deviceTokenController } from '../controllers/deviceToken.controller';
import { verifyJWT } from '../middlewares/auth.middleware';

const router = Router();

// Test endpoint for Postman (supports optional target userId, raw FCM token, or JWT user)
router.post('/test', deviceTokenController.sendTestNotification);

router.use(verifyJWT);

router.post('/', deviceTokenController.registerToken);
router.delete('/', deviceTokenController.removeToken);

export default router;

