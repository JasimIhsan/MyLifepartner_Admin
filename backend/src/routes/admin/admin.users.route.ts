import adminUsersController from "@/controllers/admin/admin.users.controller";
import { Router } from "express";

const adminUsersRoute = Router();

adminUsersRoute.get("/", adminUsersController.getAllUsers);
adminUsersRoute.post("/", adminUsersController.createUser);
adminUsersRoute.put("/:id", adminUsersController.updateUser);
adminUsersRoute.patch("/:id/block-status", adminUsersController.toggleBlockUser);
adminUsersRoute.delete("/:id", adminUsersController.deleteUser);

export default adminUsersRoute;
