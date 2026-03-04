import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import userService from "../../services/user.service";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

class UserController {
   public getUsers = asyncHandler(async (req: Request, res: Response) => {
      const findAllUsersData = await userService.getUsers();
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findAllUsersData, "findAll"));
   });

   public getUserById = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const findOneUserData = await userService.getUserById(userId);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findOneUserData, "findOne"));
   });

   public createUser = asyncHandler(async (req: Request, res: Response) => {
      const userData = req.body;
      const createUserData = await userService.createUser(userData);
      res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, createUserData, "created"));
   });

   public updateUser = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const { name, ...restData } = req.body;

      const updatePayload: any = { ...restData };
      if (name !== undefined) {
         updatePayload.profile = {
            update: { name },
         };
      }

      const updatedUserData = await userService.updateUser(userId, updatePayload);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedUserData, "updated"));
   });
}

export default new UserController();
