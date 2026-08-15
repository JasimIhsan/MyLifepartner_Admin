import { UpdateUserDto } from "@/dtos/user.input.dto";
import { IUserService } from "@/interfaces/services/user.service.interface";
import { auditService } from "@/services/audit.service";
import { AuthRequest } from "@/types/AuthRequest";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import logger from "@/utils/logger";
import { ActorType, AuditModule, AuditSeverity, AuditSource, AuditStatus } from "@prisma/client";
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

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.ACCOUNT,
         action: "UPDATE_USER_ACCOUNT",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.INFO,
         message: `User updated account details`,
         newValue: updatePayload,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.API,
      });

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
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "User is not authorized to access this resource.");
      }
   }

   /**
    * @route POST /api/v1/user/account-deletion/request
    * @purpose Requests account deletion for the authenticated user.
    */
   public requestAccountDeletion = asyncHandler(async (req: AuthRequest, res: Response) => {
      const authUserId = this.getAuthenticatedUserId(req);
      const reason = typeof req.body?.reason === "string" ? req.body.reason.trim() : "";

      if (!reason) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Account deletion reason is required");
      }

      if (reason.length > 500) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Account deletion reason must be 500 characters or fewer");
      }

      await this.userService.requestAccountDeletion(authUserId, reason);

      await auditService.log({
         userId: authUserId,
         actorType: ActorType.USER,
         module: AuditModule.ACCOUNT,
         action: "REQUEST_ACCOUNT_DELETION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.WARNING,
         message: `User requested account deletion.`,
         newValue: { reason },
         entityType: "User",
         entityId: authUserId.toString(),
         source: AuditSource.API,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Account deletion verification email sent"));
   });

   /**
    * @route GET /api/v1/user/account-deletion/verify
    * @purpose Verifies account deletion token and redirects to app.
    */
   public verifyAccountDeletion = asyncHandler(async (req: Request, res: Response) => {
      const token = req.query.token as string;

      if (!token) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Token is required");
      }

      const userId = await this.userService.verifyAccountDeletion(token);

      await auditService.log({
         userId,
         actorType: ActorType.USER,
         module: AuditModule.ACCOUNT,
         action: "VERIFY_ACCOUNT_DELETION",
         status: AuditStatus.SUCCESS,
         severity: AuditSeverity.CRITICAL,
         message: `User verified account deletion request via email link.`,
         entityType: "User",
         entityId: userId.toString(),
         source: AuditSource.API,
      });

      const html = `
         <!DOCTYPE html>
         <html>
         <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>Request Verified</title>
            <style>
               body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; text-align: center; padding: 40px 20px; background-color: #f9fafb; color: #111827; }
               .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px 30px; border-radius: 12px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); }
               h1 { color: #10b981; margin-bottom: 16px; font-size: 24px; }
               p { font-size: 16px; color: #4b5563; line-height: 1.5; margin-bottom: 30px; }
               .btn { display: inline-block; background-color: #ff4b4b; color: white; text-decoration: none; padding: 12px 24px; border-radius: 8px; font-weight: 600; font-size: 16px; transition: background-color 0.2s; }
               .btn:hover { background-color: #e04343; }
            </style>
         </head>
         <body>
            <div class="container">
               <h1>Verification Successful</h1>
               <p>Your account deletion request has been verified and is pending admin approval.</p>
            </div>
            <script>
               // Attempt to automatically redirect after 2 seconds
               setTimeout(() => {
                  window.location.href = "lifepartneragain://account-deleted";
               }, 2000);
            </script>
         </body>
         </html>
      `;

      return res.status(200).send(html);
   });
}
