import { CreateLegalDocumentDto, ILegalDocumentService } from "@/interfaces/services/legal-document.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";
import { LegalDocument, LegalDocumentType, LegalDocumentStatus } from "@prisma/client";
import prisma from "@/config/prisma";

export class LegalDocumentService implements ILegalDocumentService {
   public async getLatestPublished(type: LegalDocumentType): Promise<LegalDocument | null> {
      return prisma.legalDocument.findFirst({
         where: {
            type,
            status: LegalDocumentStatus.PUBLISHED,
         },
         orderBy: {
            publishedAt: 'desc',
         },
      });
   }

   public async createDocument(data: CreateLegalDocumentDto): Promise<LegalDocument> {
      return prisma.legalDocument.create({
         data: {
            ...data,
            status: LegalDocumentStatus.DRAFT,
         },
      });
   }

   public async updateDocument(id: number, data: Partial<CreateLegalDocumentDto>): Promise<LegalDocument> {
      const existing = await prisma.legalDocument.findUnique({ where: { id } });
      if (!existing) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Legal document not found");
      }

      if (existing.status === LegalDocumentStatus.PUBLISHED) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Cannot edit a published document. Create a new draft instead.");
      }

      return prisma.legalDocument.update({
         where: { id },
         data,
      });
   }

   public async publishDocument(id: number): Promise<LegalDocument> {
      const existing = await prisma.legalDocument.findUnique({ where: { id } });
      if (!existing) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Legal document not found");
      }

      if (existing.status === LegalDocumentStatus.PUBLISHED) {
         return existing;
      }

      // Start transaction to unpublish existing and publish new one
      const [, publishedDoc] = await prisma.$transaction([
         // Unpublish current published doc of the same type
         prisma.legalDocument.updateMany({
            where: {
               type: existing.type,
               status: LegalDocumentStatus.PUBLISHED,
            },
            data: {
               status: LegalDocumentStatus.DRAFT,
            },
         }),
         // Publish the new document
         prisma.legalDocument.update({
            where: { id },
            data: {
               status: LegalDocumentStatus.PUBLISHED,
               publishedAt: new Date(),
            },
         }),
      ]);

      return publishedDoc;
   }

   public async getDocuments(type?: LegalDocumentType): Promise<LegalDocument[]> {
      const where = type ? { type } : {};
      return prisma.legalDocument.findMany({
         where,
         orderBy: {
            createdAt: 'desc',
         },
      });
   }

   public async getDocumentById(id: number): Promise<LegalDocument | null> {
      return prisma.legalDocument.findUnique({ where: { id } });
   }
}
