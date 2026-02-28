import userService from "@/services/user.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";

class AdminUsersController {
   getAllUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { search, page, limit } = req.query;
      const pageNumber = page ? parseInt(page as string) : undefined;
      const limitNumber = limit ? parseInt(limit as string) : undefined;

      const { data, total } = await userService.getUsers(search as string | undefined, pageNumber, limitNumber);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Users fetched successfully"));
   });

   createUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const result = await userService.createUser(req.body);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User created successfully"));
   });

   updateUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const result = await userService.updateUser(userId, req.body);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User updated successfully"));
   });

   toggleBlockUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const result = await userService.toggleBlockUser(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User block status toggled successfully"));
   });

   deleteUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      await userService.deleteUser(userId);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "User deleted successfully"));
   });
}

export default new AdminUsersController();
