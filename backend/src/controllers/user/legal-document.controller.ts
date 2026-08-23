import { ILegalDocumentService } from "@/interfaces/services/legal-document.service.interface";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { LegalDocumentType } from "@prisma/client";

export class UserLegalDocumentController {
   constructor(private readonly legalDocumentService: ILegalDocumentService) {}

   public getLatestTerms = asyncHandler(async (req: Request, res: Response) => {
      const document = await this.legalDocumentService.getLatestPublished(LegalDocumentType.TERMS);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Terms retrieved successfully"));
   });

   public getLatestPrivacyPolicy = asyncHandler(async (req: Request, res: Response) => {
      const document = await this.legalDocumentService.getLatestPublished(LegalDocumentType.PRIVACY_POLICY);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Privacy policy retrieved successfully"));
   });
}
