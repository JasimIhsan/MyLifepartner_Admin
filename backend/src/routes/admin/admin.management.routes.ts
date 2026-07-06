import { adminManagementController } from "@/composer/composer";
import { Router } from "express";
import { isSuperAdmin } from "../../middlewares/superAdmin.middleware";

const adminManagementRoute = Router();

adminManagementRoute.use(isSuperAdmin);

/**
 * @route   GET /api/v1/admin/management
 * @desc    Get all admins
 * @access  Super Admin
 */
adminManagementRoute.get("/", adminManagementController.getAllAdmins);

/**
 * @route   GET /api/v1/admin/management/:id
 * @desc    Get admin by ID
 * @access  Super Admin
 */
adminManagementRoute.get("/:id", adminManagementController.getAdminById);

/**
 * @route   POST /api/v1/admin/management
 * @desc    Create a new admin
 * @access  Super Admin
 */
adminManagementRoute.post("/", adminManagementController.createAdmin);

/**
 * @route   PUT /api/v1/admin/management/:id
 * @desc    Update admin by ID
 * @access  Super Admin
 */
adminManagementRoute.put("/:id", adminManagementController.updateAdmin);

/**
 * @route   DELETE /api/v1/admin/management/:id
 * @desc    Delete admin by ID
 * @access  Super Admin
 */
adminManagementRoute.delete("/:id", adminManagementController.deleteAdmin);

export default adminManagementRoute;
