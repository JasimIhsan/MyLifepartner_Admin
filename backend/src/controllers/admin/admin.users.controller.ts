import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";
import { CreateUserDto, UpdateUserDto } from "@/dtos/user.input.dto";

export class AdminUsersController {
   constructor(private userService: IUserService) { }

   /**
    * @route   GET /api/v1/admin/users
    * @desc    Get all users with filtering
    * @access  Private/Admin
    */
   getAllUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { search, page, limit, selfieStatus } = req.query;
      const pageNumber = page ? parseInt(page as string) : undefined;
      const limitNumber = limit ? parseInt(limit as string) : undefined;

      const { data, total } = await this.userService.getUsers(search as string | undefined, pageNumber, limitNumber, selfieStatus as string | undefined);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Users fetched successfully"));
   });

   /**
    * @route   POST /api/v1/admin/users
    * @desc    Create a new user
    * @access  Private/Admin
    */
   createUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const createPayload: CreateUserDto = req.body;
      const result = await this.userService.createUser(createPayload);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User created successfully"));
   });

   /**
    * @route   PATCH /api/v1/admin/users/:id
    * @desc    Update a user
    * @access  Private/Admin
    */
   updateUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const updatePayload: UpdateUserDto = req.body;
      const result = await this.userService.updateUser(userId, updatePayload);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User updated successfully"));
   });

   /**
    * @route   PATCH /api/v1/admin/users/:id/block
    * @desc    Toggle block status of a user
    * @access  Private/Admin
    */
   toggleBlockUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const result = await this.userService.toggleBlockUser(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User block status toggled successfully"));
   });

   /**
    * @route   DELETE /api/v1/admin/users/:id
    * @desc    Delete a user
    * @access  Private/Admin
    */
   deleteUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      await this.userService.deleteUser(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "User deleted successfully"));
   });

   /**
    * @route   GET /api/v1/admin/users/:id/selfie
    * @desc    Get user selfie details
    * @access  Private/Admin
    */
   getSelfieUrl = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const data = await this.userService.getUserSelfieData(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Selfie data fetched successfully"));
   });

   /**
    * @route   GET /api/v1/admin/users/:id/images
    * @desc    Get user uploaded images
    * @access  Private/Admin
    */
   getUserImages = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const data = await this.userService.getUserImagesData(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, data, "Images fetched successfully"));
   });

   /**
    * @route   PATCH /api/v1/admin/users/:id/verify
    * @desc    Verify user profile and selfie
    * @access  Private/Admin
    */
   verifyProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const result = await this.userService.updateUser(userId, {
         isVerified: true,
         selfieStatus: "APPROVED",
      });
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User profile verified successfully"));
   });
}
