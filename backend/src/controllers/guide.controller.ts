import { IGuideService } from "@/interfaces/services/guide.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { Request, Response } from "express";
import { z } from "zod";

const createGuideSchema = z.object({
   question: z.string().min(1, "Question is required"),
   answer: z.string().min(1, "Answer is required"),
   categoryId: z.number().int().min(1).max(4),
   bullets: z.array(z.string()).default([]),
});

const updateGuideSchema = createGuideSchema.partial();

export class GuideController {
   constructor(private readonly guideService: IGuideService) {}

   /** GET /user/guides */
   getGuides = asyncHandler(async (req: Request, res: Response) => {
      const categoryId = req.query.categoryId ? parseInt(req.query.categoryId as string) : undefined;
      const search = req.query.search ? (req.query.search as string) : undefined;

      const { guides, total } = await this.guideService.getAllGuides({ categoryId, search });
      
      const categories = [
         { id: 1, name: "About LPA" },
         { id: 2, name: "Safety & Privacy" },
         { id: 3, name: "Account & Trust" },
         { id: 4, name: "Membership" }
      ];

      res.status(200).json(new ApiResponse(200, { guides, total, categories }, "Guides retrieved successfully"));
   });

   /** GET /admin/guides */
   adminGetGuides = asyncHandler(async (req: Request, res: Response) => {
      const page = req.query.page ? parseInt(req.query.page as string) : 1;
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 10;
      const categoryId = req.query.categoryId ? parseInt(req.query.categoryId as string) : undefined;
      const search = req.query.search ? (req.query.search as string) : undefined;

      const { guides, total } = await this.guideService.getAllGuides({ categoryId, search, page, limit });
      res.status(200).json(new ApiResponse(200, { guides, total, page, limit }, "All guides retrieved successfully"));
   });

   /** GET /admin/guides/:id */
   getGuideById = asyncHandler(async (req: Request, res: Response) => {
      const id = parseInt(req.params.id as string);
      if (isNaN(id)) {
         throw new ApiError(400, "Invalid Guide ID");
      }
      const guide = await this.guideService.getGuideById(id);
      if (!guide) {
         throw new ApiError(404, "Guide not found");
      }
      res.status(200).json(new ApiResponse(200, guide, "Guide retrieved successfully"));
   });

   /** POST /admin/guides */
   createGuide = asyncHandler(async (req: Request, res: Response) => {
      const parsed = createGuideSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const guide = await this.guideService.createGuide(parsed.data);
      res.status(201).json(new ApiResponse(201, guide, "Guide question created successfully"));
   });

   /** PUT /admin/guides/:id */
   updateGuide = asyncHandler(async (req: Request, res: Response) => {
      const id = parseInt(req.params.id as string);
      if (isNaN(id)) {
         throw new ApiError(400, "Invalid Guide ID");
      }
      const parsed = updateGuideSchema.safeParse(req.body);
      if (!parsed.success) {
         throw new ApiError(400, parsed.error.issues[0].message);
      }
      const guide = await this.guideService.updateGuide(id, parsed.data);
      res.status(200).json(new ApiResponse(200, guide, "Guide question updated successfully"));
   });

   /** DELETE /admin/guides/:id */
   deleteGuide = asyncHandler(async (req: Request, res: Response) => {
      const id = parseInt(req.params.id as string);
      if (isNaN(id)) {
         throw new ApiError(400, "Invalid Guide ID");
      }
      await this.guideService.deleteGuide(id);
      res.status(200).json(new ApiResponse(200, null, "Guide question deleted successfully"));
   });
}
