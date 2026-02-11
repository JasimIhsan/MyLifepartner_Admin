import { Request, Response } from "express";
import userService from "../../services/user.service";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

class UserController {
   public getUsers = asyncHandler(async (req: Request, res: Response) => {
      const findAllUsersData = await userService.getUsers();
      res.status(200).json(new ApiResponse(200, findAllUsersData, "findAll"));
   });

   public getUserById = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const findOneUserData = await userService.getUserById(userId);
      res.status(200).json(new ApiResponse(200, findOneUserData, "findOne"));
   });

   public createUser = asyncHandler(async (req: Request, res: Response) => {
      const userData = req.body;
      const createUserData = await userService.createUser(userData);
      res.status(201).json(new ApiResponse(201, createUserData, "created"));
   });
}

export default new UserController();
