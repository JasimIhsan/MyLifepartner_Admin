import { ILegalDocumentService } from "@/interfaces/services/legal-document.service.interface";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { LegalDocumentType } from "@prisma/client";
import prisma from "@/config/prisma";
import { ApiError } from "@/utils/ApiError";

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

   public getAcceptedDocument = asyncHandler(async (req: Request, res: Response) => {
      const userId = req.user?.id;
      if (!userId) {
         throw new ApiError(HTTP_STATUS.UNAUTHORIZED, "Unauthorized");
      }

      const { type } = req.params; // "terms" or "privacy"
      let legalType: LegalDocumentType;
      if (type === "terms") {
         legalType = LegalDocumentType.TERMS;
      } else if (type === "privacy") {
         legalType = LegalDocumentType.PRIVACY_POLICY;
      } else {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid document type");
      }

      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User not found");
      }

      const version = legalType === LegalDocumentType.TERMS ? user.termsVersion : user.privacyVersion;
      if (!version) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "User has not accepted this document");
      }

      const document = await this.legalDocumentService.getDocumentByVersion(legalType, version);
      if (!document) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Accepted document version not found");
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Accepted document retrieved successfully"));
   });
}
