import { IUserService } from "@/interfaces/services/user.service.interface";
import { HTTP_STATUS } from "@/utils/constants";
import { Prisma } from "@prisma/client";
import { Request, Response } from "express";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

export class UserController {
   constructor(private userService: IUserService) {}

   public getUsers = asyncHandler(async (req: Request, res: Response) => {
      const findAllUsersData = await this.userService.getUsers();
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findAllUsersData, "findAll"));
   });

   public getUserById = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const findOneUserData = await this.userService.getUserById(userId);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findOneUserData, "findOne"));
   });

   public createUser = asyncHandler(async (req: Request, res: Response) => {
      const userData = req.body;
      const createUserData = await this.userService.createUser(userData);
      res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, createUserData, "created"));
   });

   public updateUser = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const { name, ...restData } = req.body;

      const updatePayload: Prisma.UserUpdateInput = { ...restData };
      if (name !== undefined) {
         updatePayload.profile = {
            update: { name },
         };
      }

      const updatedUserData = await this.userService.updateUser(userId, updatePayload);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedUserData, "updated"));
   });
}
