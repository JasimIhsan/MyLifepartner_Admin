import { zegoController } from "@/composer/composer";
import { verifyJWT } from "@/middlewares/auth.middleware";
import { Router } from "express";

const router = Router();

router.use(verifyJWT);

router.get("/token", zegoController.getToken);

export default router;
