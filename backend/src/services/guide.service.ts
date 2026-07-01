import { Guide, Prisma } from "@prisma/client";
import { IGuideRepository } from "../interfaces/repositories/guide.repository.interface";
import { GuideFilters, IGuideService } from "../interfaces/services/guide.service.interface";

export class GuideService implements IGuideService {
   constructor(private readonly guideRepository: IGuideRepository) {}

   async createGuide(data: Prisma.GuideCreateInput): Promise<Guide> {
      return this.guideRepository.create(data);
   }

   async getAllGuides(filters: GuideFilters): Promise<{ guides: Guide[]; total: number }> {
      const { categoryId, search, page, limit } = filters;

      const where: Prisma.GuideWhereInput = {};
      if (categoryId && !isNaN(categoryId)) {
         where.categoryId = categoryId;
      }
      if (search && search.trim().length > 0) {
         const cleanSearch = search.trim();
         where.OR = [
            { question: { contains: cleanSearch, mode: "insensitive" } },
            { answer: { contains: cleanSearch, mode: "insensitive" } },
         ];
      }

      let skip: number | undefined;
      let take: number | undefined;
      if (page && limit) {
         skip = (page - 1) * limit;
         take = limit;
      }

      return this.guideRepository.findAll(where, skip, take);
   }

   async getGuideById(id: number): Promise<Guide | null> {
      return this.guideRepository.findById(id);
   }

   async updateGuide(id: number, data: Prisma.GuideUpdateInput): Promise<Guide> {
      return this.guideRepository.update(id, data);
   }

   async deleteGuide(id: number): Promise<Guide> {
      return this.guideRepository.delete(id);
   }
}
