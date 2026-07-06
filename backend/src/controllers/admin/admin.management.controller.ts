import { CreateAdminDto, UpdateAdminDto } from "@/dtos/admin.management.dto";
import { IAdminManagementService } from "@/interfaces/services/admin.management.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";

export class AdminManagementController {
   constructor(private readonly adminManagementService: IAdminManagementService) {}

   /**
    * @route GET /api/v1/admin/management
    * @purpose Fetches all admins.
    */
   public getAllAdmins = asyncHandler(async (_req: Request, res: Response) => {
      const admins = await this.adminManagementService.getAllAdmins();

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admins }, "Admins fetched successfully"));
   });

   /**
    * @route GET /api/v1/admin/management/:id
    * @purpose Fetches admin details by ID.
    */
   public getAdminById = asyncHandler(async (req: Request, res: Response) => {
      const adminId = Number(req.params.id);

      if (!Number.isInteger(adminId) || adminId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid admin ID");
      }

      const admin = await this.adminManagementService.getAdminById(adminId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admin }, "Admin fetched successfully"));
   });

   /**
    * @route POST /api/v1/admin/management
    * @purpose Creates a new admin.
    */
   public createAdmin = asyncHandler(async (req: Request, res: Response) => {
      const data: CreateAdminDto = req.body;

      const admin = await this.adminManagementService.createAdmin(data);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, { admin }, "Admin created successfully"));
   });

   /**
    * @route PUT /api/v1/admin/management/:id
    * @purpose Updates admin details by ID.
    */
   public updateAdmin = asyncHandler(async (req: Request, res: Response) => {
      const adminId = Number(req.params.id);
      const data: UpdateAdminDto = req.body;

      if (!Number.isInteger(adminId) || adminId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid admin ID");
      }

      const admin = await this.adminManagementService.updateAdmin(adminId, data);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { admin }, "Admin updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/management/:id
    * @purpose Deletes an admin by ID.
    */
   public deleteAdmin = asyncHandler(async (req: AuthRequest, res: Response) => {
      const adminId = Number(req.params.id);
      const currentAdminId = this.getAuthenticatedUserId(req);

      if (!Number.isInteger(adminId) || adminId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid admin ID");
      }

      const result = await this.adminManagementService.deleteAdmin(adminId, currentAdminId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Admin deleted successfully"));
   });

   /**
    * Extracts and validates authenticated admin ID.
    */
   private getAuthenticatedUserId(req: AuthRequest): number {
      const adminId = Number(req.user?.id);

      if (!Number.isInteger(adminId) || adminId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return adminId;
   }
}
