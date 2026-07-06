import { IUserService } from "@/interfaces/services/user.service.interface";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";
import { UpdateUserDto } from "@/dtos/user.input.dto";

export class UserController {
   constructor(private userService: IUserService) {}

   /**
    * @route   GET /api/v1/user
    * @desc    Get all users
    * @access  Private/Admin
    */
   public getUsers = asyncHandler(async (req: Request, res: Response) => {
      const findAllUsersData = await this.userService.getUsers();
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findAllUsersData, "findAll"));
   });

   /**
    * @route   GET /api/v1/user/:id
    * @desc    Get user by id
    * @access  Private
    */
   public getUserById = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const findOneUserData = await this.userService.getUserById(userId);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, findOneUserData, "findOne"));
   });

   /**
    * @route   POST /api/v1/user
    * @desc    Create a new user
    * @access  Private/Admin
    */
   public createUser = asyncHandler(async (req: Request, res: Response) => {
      const userData = req.body;
      const createUserData = await this.userService.createUser(userData);
      res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, createUserData, "created"));
   });

   /**
    * @route   PATCH /api/v1/user/:id
    * @desc    Update a user
    * @access  Private
    */
   public updateUser = asyncHandler(async (req: Request, res: Response) => {
      const userId = Number(req.params.id);
      const updatePayload: UpdateUserDto = req.body;

      const updatedUserData = await this.userService.updateUser(userId, updatePayload);
      res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedUserData, "updated"));
   });
}
