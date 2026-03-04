import { userController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

router.get("/", userController.getUsers);
router.get("/:id", userController.getUserById);
router.post("/", userController.createUser);
router.patch("/:id", userController.updateUser);

export default router;
