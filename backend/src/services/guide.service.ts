import { CreateGuideCategoryDto, CreateGuideDto, UpdateGuideCategoryDto, UpdateGuideDto } from "@/dtos/guide.input.dto";
import { IGuideRepository } from "@/interfaces/repositories/guide.repository.interface";
import { Guide, GuideCategory, GuideFilters, IGuideService } from "@/interfaces/services/guide.service.interface";
import { ApiError } from "@/utils/ApiError";
import { HTTP_STATUS } from "@/utils/constants";

export class GuideService implements IGuideService {
   constructor(private readonly guideRepository: IGuideRepository) {}

   /**
    * Creates a new guide
    * @param data - The DTO containing the guide details
    * @returns The created Guide object
    */
   async createGuide(data: CreateGuideDto): Promise<Guide> {
      await this.assertCategoryExists(data.categoryId);

      return this.guideRepository.create({
         ...data,
         question: data.question.trim(),
         answer: data.answer.trim(),
         bullets: data.bullets ?? [],
      }) as unknown as Guide;
   }

   /**
    * Retrieves a paginated list of guides based on the provided filters
    * @param filters - Filtering criteria (e.g., categoryId, search, pagination)
    * @returns An object containing the list of guides and total count
    */
   async getAllGuides(filters: GuideFilters): Promise<{ guides: Guide[]; total: number; categories: GuideCategory[] }> {
      const { page, limit } = filters;
      let skip: number | undefined;
      let take: number | undefined;
      if (page && limit) {
         skip = (page - 1) * limit;
         take = limit;
      }
      const [result, categories] = await Promise.all([this.guideRepository.findAll(filters, skip, take), this.getGuideCategories()]);

      return {
         guides: result.guides as unknown as Guide[],
         total: result.total,
         categories,
      };
   }

   /**
    * Retrieves a guide by its ID
    * @param id - The ID of the guide
    * @returns The Guide object if found, otherwise null
    */
   async getGuideById(id: number): Promise<Guide | null> {
      return this.guideRepository.findById(id) as unknown as Guide | null;
   }

   /**
    * Updates an existing guide
    * @param id - The ID of the guide to update
    * @param data - The DTO containing updated fields
    * @returns The updated Guide object
    */
   async updateGuide(id: number, data: UpdateGuideDto): Promise<Guide> {
      if (data.categoryId !== undefined) {
         await this.assertCategoryExists(data.categoryId);
      }

      const updateData: UpdateGuideDto = {
         ...(data.question !== undefined && { question: data.question.trim() }),
         ...(data.answer !== undefined && { answer: data.answer.trim() }),
         ...(data.categoryId !== undefined && { categoryId: data.categoryId }),
         ...(data.bullets !== undefined && { bullets: data.bullets }),
      };

      return this.guideRepository.update(id, updateData) as unknown as Guide;
   }

   /**
    * Deletes a guide by its ID
    * @param id - The ID of the guide to delete
    * @returns The deleted Guide object
    */
   async deleteGuide(id: number): Promise<Guide> {
      return this.guideRepository.delete(id) as unknown as Guide;
   }

   /**
    * Retrieves guide categories, optionally with nested guide questions.
    * @param includeGuides - Whether to include questions and answers under each category
    * @returns Ordered guide categories
    */
   async getGuideCategories(includeGuides = false): Promise<GuideCategory[]> {
      const categories = await this.guideRepository.findCategories(includeGuides);

      return categories.map((category) => ({
         id: category.id,
         name: category.name,
         displayOrder: category.displayOrder,
         guideCount: category._count?.guides ?? category.guides?.length ?? 0,
         guides: category.guides as unknown as Guide[] | undefined,
         createdAt: category.createdAt,
         updatedAt: category.updatedAt,
      }));
   }

   /**
    * Creates a guide category.
    * @param data - The DTO containing category details
    * @returns The created guide category
    */
   async createGuideCategory(data: CreateGuideCategoryDto): Promise<GuideCategory> {
      const name = this.normalizeCategoryName(data.name);
      await this.assertCategoryNameAvailable(name);

      const category = await this.guideRepository.createCategory({
         name,
         displayOrder: data.displayOrder,
      });

      return {
         ...category,
         guideCount: 0,
      } as unknown as GuideCategory;
   }

   /**
    * Updates a guide category.
    * @param id - The ID of the category to update
    * @param data - The DTO containing updated category details
    * @returns The updated guide category
    */
   async updateGuideCategory(id: number, data: UpdateGuideCategoryDto): Promise<GuideCategory> {
      const existingCategory = await this.guideRepository.findCategoryById(id);

      if (!existingCategory) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Guide category not found");
      }

      const updateData: UpdateGuideCategoryDto = {
         ...(data.displayOrder !== undefined && { displayOrder: data.displayOrder }),
      };

      if (data.name !== undefined) {
         const name = this.normalizeCategoryName(data.name);
         await this.assertCategoryNameAvailable(name, id);
         updateData.name = name;
      }

      const category = await this.guideRepository.updateCategory(id, updateData);
      const guideCount = await this.guideRepository.countGuidesByCategory(id);

      return {
         ...category,
         guideCount,
      } as unknown as GuideCategory;
   }

   /**
    * Deletes a guide category.
    * @param id - The ID of the category to delete
    * @returns The deleted guide category
    */
   async deleteGuideCategory(id: number): Promise<GuideCategory> {
      const existingCategory = await this.guideRepository.findCategoryById(id);

      if (!existingCategory) {
         throw new ApiError(HTTP_STATUS.NOT_FOUND, "Guide category not found");
      }

      const guideCount = await this.guideRepository.countGuidesByCategory(id);

      if (guideCount > 0) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "Move or delete guide questions before deleting this category");
      }

      return this.guideRepository.deleteCategory(id) as unknown as GuideCategory;
   }

   /**
    * Ensures a guide category exists.
    *
    * @param categoryId - Guide category ID.
    */
   private async assertCategoryExists(categoryId: number): Promise<void> {
      const category = await this.guideRepository.findCategoryById(categoryId);

      if (!category) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Invalid guide category");
      }
   }

   /**
    * Ensures a category name is not already in use.
    *
    * @param name - Category name.
    * @param currentCategoryId - Category ID to ignore during updates.
    */
   private async assertCategoryNameAvailable(name: string, currentCategoryId?: number): Promise<void> {
      const categories = await this.guideRepository.findCategories();
      const matchingCategory = categories.find((category) => category.name.toLowerCase() === name.toLowerCase() && category.id !== currentCategoryId);

      if (matchingCategory) {
         throw new ApiError(HTTP_STATUS.CONFLICT, "Guide category already exists");
      }
   }

   /**
    * Normalizes category names before persistence.
    *
    * @param name - Raw category name.
    * @returns Normalized category name.
    */
   private normalizeCategoryName(name: string): string {
      const normalized = name.trim();

      if (!normalized) {
         throw new ApiError(HTTP_STATUS.BAD_REQUEST, "Category name is required");
      }

      return normalized;
   }
}
