import { IGuideService } from "@/interfaces/services/guide.service.interface";
import { ApiError } from "@/utils/ApiError";
import { ApiResponse } from "@/utils/ApiResponse";
import { asyncHandler } from "@/utils/asyncHandler";
import { HTTP_STATUS } from "@/utils/constants";
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

   /**
    * @route GET /api/v1/user/guide
    * @purpose Fetches active guide questions for users.
    */
   public getGuides = asyncHandler(async (req: Request, res: Response) => {
      const categoryId = req.query.categoryId ? Number(req.query.categoryId) : undefined;
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;

      if (categoryId !== undefined && (!Number.isInteger(categoryId) || categoryId <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid category ID");
      }

      const { guides, total, categories } = await this.guideService.getAllGuides({
         categoryId,
         search,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { guides, total, categories }, "Guides retrieved successfully"));
   });

   /**
    * @route GET /api/v1/admin/guides
    * @purpose Fetches all guides for admin with pagination.
    */
   public adminGetGuides = asyncHandler(async (req: Request, res: Response) => {
      const page = req.query.page ? Number(req.query.page) : 1;
      const limit = req.query.limit ? Number(req.query.limit) : 10;
      const categoryId = req.query.categoryId ? Number(req.query.categoryId) : undefined;
      const search = typeof req.query.search === "string" ? req.query.search.trim() : undefined;

      if (!Number.isInteger(page) || page <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid page");
      }

      if (!Number.isInteger(limit) || limit <= 0 || limit > 100) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid limit");
      }

      if (categoryId !== undefined && (!Number.isInteger(categoryId) || categoryId <= 0)) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid category ID");
      }

      const { guides, total } = await this.guideService.getAllGuides({
         categoryId,
         search,
         page,
         limit,
      });

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, { guides, total, page, limit }, "All guides retrieved successfully"));
   });

   /**
    * @route GET /api/v1/user/guide/:id
    * @purpose Fetches guide details by ID.
    */
   public getGuideById = asyncHandler(async (req: Request, res: Response) => {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid guide ID");
      }

      const guide = await this.guideService.getGuideById(id);

      if (!guide) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Guide not found");
      }

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, guide, "Guide retrieved successfully"));
   });

   /**
    * @route POST /api/v1/admin/guides
    * @purpose Creates a new guide question.
    */
   public createGuide = asyncHandler(async (req: Request, res: Response) => {
      const parsed = createGuideSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const guide = await this.guideService.createGuide(parsed.data);

      return res.status(HTTP_STATUS.CREATED).json(new ApiResponse(HTTP_STATUS.CREATED, guide, "Guide question created successfully"));
   });

   /**
    * @route PUT /api/v1/admin/guides/:id
    * @purpose Updates a guide question by ID.
    */
   public updateGuide = asyncHandler(async (req: Request, res: Response) => {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid guide ID");
      }

      const parsed = updateGuideSchema.safeParse(req.body);

      if (!parsed.success) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, parsed.error.issues[0].message);
      }

      const guide = await this.guideService.updateGuide(id, parsed.data);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, guide, "Guide question updated successfully"));
   });

   /**
    * @route DELETE /api/v1/admin/guides/:id
    * @purpose Deletes a guide question by ID.
    */
   public deleteGuide = asyncHandler(async (req: Request, res: Response) => {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid guide ID");
      }

      await this.guideService.deleteGuide(id);

      return res.status(HTTP_STATUS.OK).json(new ApiResponse(HTTP_STATUS.OK, null, "Guide question deleted successfully"));
   });
}
