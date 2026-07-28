import { UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import logger from "@/utils/logger";
import { Request, Response } from "express";

export class UserController {
   constructor(private readonly userService: IUserService) {}

   /**
    * @route GET /api/v1/user
    * @purpose Fetches all users.
    */
   public getUsers = asyncHandler(async (_req: Request, res: Response) => {
      const users = await this.userService.getUsers();

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, users, "Users fetched successfully"));
   });

   /**
    * @route GET /api/v1/user/:id
    * @purpose Fetches user details by ID.
    */
   public getUserById = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.id);

      logger.debug(`User ID: ${userId}`);
      logger.debug(`Auth User ID: ${authUserId}`);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const user = await this.userService.getUserById(userId);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, user, "User fetched successfully"));
   });

   /**
    * @route POST /api/v1/user
    * @purpose Creates a new user.
    */
   public createUser = asyncHandler(async (req: Request, res: Response) => {
      const user = await this.userService.createUser(req.body);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, user, "User created successfully"));
   });

   /**
    * @route PATCH /api/v1/user/:id
    * @purpose Updates user details by ID.
    */
   public updateUser = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const userId = Number(req.params.id);
      const updatePayload: UpdateUserDto = req.body;

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid user ID");
      }

      this.ensureUserOwnsResource(userId, authUserId);

      const updatedUser = await this.userService.updateUser(userId, updatePayload);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, updatedUser, "User updated successfully"));
   });

   /**
    * Extracts and validates authenticated user ID.
    */
   private getAuthenticatedUserId(req: AuthRequest): number {
      const userId = Number(req.user?.id);
      logger.debug(`Auth User ID: ${userId}`);

      if (!Number.isInteger(userId) || userId <= 0) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      return userId;
   }

   /**
    * Ensures authenticated user owns the requested resource.
    */
   private ensureUserOwnsResource(resourceUserId: number, authUserId: number): void {
      if (resourceUserId !== authUserId) {
         throw new ApiError(HTTP_STATUS.FORBIDDEN, "Forbidden");
      }
   }
}
