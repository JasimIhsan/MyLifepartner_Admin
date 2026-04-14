import { ZegoService } from "@/services/zego.service";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";

export class ZegoController {
   constructor(private readonly zegoService: ZegoService) {}

   /**
    * GET /zego/token
    * Returns a ZEGOCLOUD access token for the authenticated user.
    */
   getToken = asyncHandler(async (req: Request, res: Response) => {
      const userId = String(req.user!.id);
      const token = this.zegoService.generateToken(userId);

      res.status(200).json(
         new ApiResponse(200, { token, userId }, "ZEGO token generated"),
      );
   });
}
