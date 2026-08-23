import { adminLegalDocumentController } from "@/composer/composer";
import { Router } from "express";

const router = Router();

/**
 * @route   POST /api/v1/admin/legal-documents
 * @desc    Create a new legal document (draft)
 */
router.post("/", adminLegalDocumentController.createDocument);

/**
 * @route   GET /api/v1/admin/legal-documents
 * @desc    Get all legal documents
 */
router.get("/", adminLegalDocumentController.getDocuments);

/**
 * @route   GET /api/v1/admin/legal-documents/:id
 * @desc    Get legal document by id
 */
router.get("/:id", adminLegalDocumentController.getDocumentById);

/**
 * @route   PUT /api/v1/admin/legal-documents/:id
 * @desc    Update a legal document (only drafts can be updated)
 */
router.put("/:id", adminLegalDocumentController.updateDocument);

/**
 * @route   POST /api/v1/admin/legal-documents/:id/publish
 * @desc    Publish a legal document (archives old published)
 */
router.post("/:id/publish", adminLegalDocumentController.publishDocument);

export default router;
