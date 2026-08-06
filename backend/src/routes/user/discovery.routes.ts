import { Router } from "express";
import { discoveryController } from "@/composer/composer";
import { verifyJWT } from "../../middlewares/auth.middleware";

const router = Router();

router.use(verifyJWT);

router.get("/profiles", discoveryController.discoverProfiles);

export default router;
