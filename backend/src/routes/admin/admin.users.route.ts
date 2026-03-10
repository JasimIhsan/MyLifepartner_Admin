import { adminUsersController } from "@/composer/composer";
import { Router } from "express";

const adminUsersRoute = Router();

adminUsersRoute.get("/", adminUsersController.getAllUsers);
adminUsersRoute.post("/", adminUsersController.createUser);
adminUsersRoute.put("/:id", adminUsersController.updateUser);
adminUsersRoute.get("/:id/selfie-url", adminUsersController.getSelfieUrl);
adminUsersRoute.get("/:id/images", adminUsersController.getUserImages);
adminUsersRoute.patch("/:id/verify-profile", adminUsersController.verifyProfile);
adminUsersRoute.patch("/:id/block-status", adminUsersController.toggleBlockUser);
adminUsersRoute.delete("/:id", adminUsersController.deleteUser);

export default adminUsersRoute;
