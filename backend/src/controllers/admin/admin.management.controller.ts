import { Request, Response } from "express";
import { CreateAdminDto, UpdateAdminDto } from "../../dtos/admin.management.dto";
import adminManagementService from "../../services/admin/admin.management.service";
import { AuthRequest } from "../../types/AuthRequest";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";
import { HTTP_STATUS } from "../../utils/constants";

class AdminManagementController {
   getAllAdmins = asyncHandler(async (req: Request, res: Response) => {
      const admins = await adminManagementService.getAllAdmins();
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admins }, "Admins fetched successfully"));
   });

   getAdminById = asyncHandler(async (req: Request, res: Response) => {
      const id = parseInt(req.params.id as string);
      const admin = await adminManagementService.getAdminById(id);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admin }, "Admin fetched successfully"));
   });

   createAdmin = asyncHandler(async (req: Request, res: Response) => {
      const data: CreateAdminDto = req.body;
      const admin = await adminManagementService.createAdmin(data);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, { admin }, "Admin created successfully"));
   });

   updateAdmin = asyncHandler(async (req: Request, res: Response) => {
      const id = parseInt(req.params.id as string);
      const data: UpdateAdminDto = req.body;
      const admin = await adminManagementService.updateAdmin(id, data);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admin }, "Admin updated successfully"));
   });

   deleteAdmin = asyncHandler(async (req: AuthRequest, res: Response) => {
      const id = parseInt(req.params.id as string);
      const currentAdminId = req.user!.id;
      const result = await adminManagementService.deleteAdmin(id, currentAdminId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Admin deleted successfully"));
   });
}

export default new AdminManagementController();
