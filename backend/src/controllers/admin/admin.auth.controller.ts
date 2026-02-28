import adminAuthService from "@/services/admin/admin.auth.service";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

class AdminAuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      const { username, password } = req.body;
      const result = await adminAuthService.login(username, password);
      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, result, "Admin logged in successfully"));
   });
}

export default new AdminAuthController();
