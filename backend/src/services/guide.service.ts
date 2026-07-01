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

      let skip: number | undefined;
      let take: number | undefined;
      if (page && limit) {
         skip = (page - 1) * limit;
         take = limit;
      }

      if (search && search.trim().length > 0) {
         const cleanSearch = search.trim();
         const stopWords = new Set([
            "how", "to", "can", "i", "do", "the", "a", "an", "is", "my", "your",
            "we", "us", "me", "should", "would", "could", "will", "shall",
            "please", "help", "about", "what", "where", "when", "why", "who",
            "any", "some", "there", "their", "them", "they", "he", "she", "it", "you"
         ]);

         const keywords = cleanSearch
            .toLowerCase()
            .replace(/[^\w\s]/g, "")
            .split(/\s+/)
            .filter(word => word.length > 0 && !stopWords.has(word));

         if (keywords.length > 0) {
            // 1. Try matching ALL keywords (AND)
            const andWhere: Prisma.GuideWhereInput = {
               ...where,
               AND: keywords.map(kw => ({
                  OR: [
                     { question: { contains: kw, mode: "insensitive" } },
                     { answer: { contains: kw, mode: "insensitive" } },
                  ],
               })),
            };
            const result = await this.guideRepository.findAll(andWhere, skip, take);
            if (result.total > 0) {
               return result;
            }

            // 2. Fallback to matching ANY keyword (OR) if ALL keyword search yielded nothing
            const orWhere: Prisma.GuideWhereInput = {
               ...where,
               OR: keywords.map(kw => ({
                  OR: [
                     { question: { contains: kw, mode: "insensitive" } },
                     { answer: { contains: kw, mode: "insensitive" } },
                  ],
               })),
            };
            const orResult = await this.guideRepository.findAll(orWhere, skip, take);
            if (orResult.total > 0) {
               return orResult;
            }
         }

         // 3. Fallback to simple contains match on the raw search string
         const fallbackWhere: Prisma.GuideWhereInput = {
            ...where,
            OR: [
               { question: { contains: cleanSearch, mode: "insensitive" } },
               { answer: { contains: cleanSearch, mode: "insensitive" } },
            ],
         };
         return this.guideRepository.findAll(fallbackWhere, skip, take);
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
