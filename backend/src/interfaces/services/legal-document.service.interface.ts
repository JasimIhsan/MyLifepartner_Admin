import { LegalDocument, LegalDocumentType, LegalDocumentStatus } from "@prisma/client";

export interface CreateLegalDocumentDto {
   type: LegalDocumentType;
   title: string;
   content: string;
   version: string;
}

export interface ILegalDocumentService {
   /**
    * Retrieves the latest published document of a given type.
    */
   getLatestPublished(type: LegalDocumentType): Promise<LegalDocument | null>;

   /**
    * Creates a new legal document (defaults to DRAFT).
    */
   createDocument(data: CreateLegalDocumentDto): Promise<LegalDocument>;

   /**
    * Updates an existing legal document.
    */
   updateDocument(id: number, data: Partial<CreateLegalDocumentDto>): Promise<LegalDocument>;

   /**
    * Publishes a draft document. 
    * This will archive/draft the currently published document of the same type.
    */
   publishDocument(id: number): Promise<LegalDocument>;

   /**
    * Gets all documents with optional filtering.
    */
   getDocuments(type?: LegalDocumentType): Promise<LegalDocument[]>;
   
   /**
    * Gets a single document by ID.
    */
   getDocumentById(id: number): Promise<LegalDocument | null>;
}
