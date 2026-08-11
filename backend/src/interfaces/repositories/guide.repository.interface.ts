import { Guide, GuideCategory } from "@prisma/client";
import { CreateGuideCategoryDto, CreateGuideDto, UpdateGuideCategoryDto, UpdateGuideDto } from "@/dtos/guide.input.dto";
import { GuideFilters } from "@/interfaces/services/guide.service.interface";

export type GuideCategoryWithRelations = GuideCategory & {
   guides?: Guide[];
   _count?: {
      guides: number;
   };
};

export interface IGuideRepository {
   create(data: CreateGuideDto): Promise<Guide>;
   findAll(filters?: GuideFilters, skip?: number, take?: number): Promise<{ guides: Guide[]; total: number }>;
   findById(id: number): Promise<Guide | null>;
   update(id: number, data: UpdateGuideDto): Promise<Guide>;
   delete(id: number): Promise<Guide>;
   findCategories(includeGuides?: boolean): Promise<GuideCategoryWithRelations[]>;
   findCategoryById(id: number): Promise<GuideCategory | null>;
   createCategory(data: CreateGuideCategoryDto): Promise<GuideCategory>;
   updateCategory(id: number, data: UpdateGuideCategoryDto): Promise<GuideCategory>;
   deleteCategory(id: number): Promise<GuideCategory>;
   countGuidesByCategory(categoryId: number): Promise<number>;
}
