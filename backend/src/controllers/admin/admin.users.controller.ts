import userService from "@/services/user.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Response } from "express";

class AdminUsersController {
   getAllUsers = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { search, page, limit, selfieStatus } = req.query;
      const pageNumber = page ? parseInt(page as string) : undefined;
      const limitNumber = limit ? parseInt(limit as string) : undefined;

      const { data, total } = await userService.getUsers(search as string | undefined, pageNumber, limitNumber, selfieStatus as string | undefined);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { data, total }, "Users fetched successfully"));
   });

   createUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const { name, ...restData } = req.body;
      const createPayload: import("@prisma/client").Prisma.UserCreateInput = { ...restData };
      if (name !== undefined) {
         createPayload.profile = {
            create: { name } as import("@prisma/client").Prisma.ProfileCreateWithoutUserInput,
         };
      }
      const result = await userService.createUser(createPayload);
      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, result, "User created successfully"));
   });

   updateUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const { name, ...restData } = req.body;
      const updatePayload: import("@prisma/client").Prisma.UserUpdateInput = { ...restData };
      if (name !== undefined) {
         updatePayload.profile = {
            update: { name } as import("@prisma/client").Prisma.ProfileUpdateWithoutUserInput,
         };
      }
      const result = await userService.updateUser(userId, updatePayload);
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

   getSelfieUrl = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const user = await userService.getUserById(userId);
      if (!user.selfieUrl) {
         return res.status(HTTP_STATUS.NOT_FOUND).json(new ApiResponse(HTTP_STATUS.NOT_FOUND, null, "User has no uploaded selfie"));
      }

      const { s3Service } = await import("@/services/s3.service");
      const signedUrl = await s3Service.getPresignedUrl(user.selfieUrl, 3600);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { url: signedUrl }, "Signed URL generated successfully"));
   });

   verifyProfile = asyncHandler(async (req: AuthRequest, res: Response) => {
      const userId = parseInt(req.params.id as string);
      const { SelfieStatus } = await import("@prisma/client");
      const result = await userService.updateUser(userId, {
         isVerified: true,
         profile: { update: { selfieStatus: SelfieStatus.APPROVED } },
      });
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "User profile verified successfully"));
   });
}

export default new AdminUsersController();
