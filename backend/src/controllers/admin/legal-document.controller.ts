import { ILegalDocumentService } from "@/interfaces/services/legal-document.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
import { Request, Response } from "express";
import { LegalDocumentType } from "@prisma/client";

export class AdminLegalDocumentController {
   constructor(private readonly legalDocumentService: ILegalDocumentService) {}

   public createDocument = asyncHandler(async (req: Request, res: Response) => {
      const { type, title, content, version } = req.body;

      if (!type || !title || !content || !version) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Missing required fields: type, title, content, version");
      }

      if (!Object.values(LegalDocumentType).includes(type)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid document type");
      }

      const document = await this.legalDocumentService.createDocument({
         type,
         title,
         content,
         version,
      });

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, document, "Document created successfully"));
   });

   public updateDocument = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;
      const { title, content, version } = req.body;

      const document = await this.legalDocumentService.updateDocument(Number(id), {
         title,
         content,
         version,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Document updated successfully"));
   });

   public publishDocument = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;

      const document = await this.legalDocumentService.publishDocument(Number(id));

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Document published successfully"));
   });

   public getDocuments = asyncHandler(async (req: Request, res: Response) => {
      const type = req.query.type as LegalDocumentType | undefined;

      const documents = await this.legalDocumentService.getDocuments(type);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, documents, "Documents retrieved successfully"));
   });
   
   public getDocumentById = asyncHandler(async (req: Request, res: Response) => {
      const { id } = req.params;

      const document = await this.legalDocumentService.getDocumentById(Number(id));
      if (!document) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Document not found");
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, document, "Document retrieved successfully"));
   });
}
