import { Router } from "express";
import adminManagementController from "../../controllers/admin/admin.management.controller";
import { verifyJWT } from "../../middlewares/auth.middleware";
import { isSuperAdmin } from "../../middlewares/superAdmin.middleware";

const adminManagementRoute = Router();

adminManagementRoute.use(verifyJWT, isSuperAdmin);

adminManagementRoute.get("/", adminManagementController.getAllAdmins);
adminManagementRoute.get("/:id", adminManagementController.getAdminById);
adminManagementRoute.post("/", adminManagementController.createAdmin);
adminManagementRoute.put("/:id", adminManagementController.updateAdmin);
adminManagementRoute.delete("/:id", adminManagementController.deleteAdmin);

export default adminManagementRoute;
