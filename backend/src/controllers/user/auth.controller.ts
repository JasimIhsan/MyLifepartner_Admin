import { Request, Response } from "express";
import { ApiResponse } from "../../utils/ApiResponse";
import { asyncHandler } from "../../utils/asyncHandler";

class AuthController {
   login = asyncHandler(async (req: Request, res: Response) => {
      return res.status(200).json(new ApiResponse(200, { user: "demo_user" }, "User login success"));
   });
}

export default new AuthController();
