import { Router } from "express";
import { DiscoveryController } from "../../controllers/user/discovery.controller";
import { verifyJWT } from "../../middlewares/auth.middleware";

const router = Router();
const discoveryController = new DiscoveryController();

router.use(verifyJWT);

router.get("/profiles", discoveryController.discoverProfiles);

export default router;
