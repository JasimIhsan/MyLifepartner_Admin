import prisma from "@/config/prisma";
import { CreateGuideDto, UpdateGuideDto } from "@/dtos/guide.input.dto";
import { GuideFilters } from "@/interfaces/services/guide.service.interface";
import { Guide, Prisma } from "@prisma/client";
import { IGuideRepository } from "../interfaces/repositories/guide.repository.interface";

type PaginatedGuides = {
   guides: Guide[];
   total: number;
};

export class GuideRepository implements IGuideRepository {
   /**
    * Creates a guide.
    *
    * @param data - Guide creation data.
    * @returns Created guide.
    */
   async create(data: CreateGuideDto): Promise<Guide> {
      const nextDisplayOrder = await this.getNextDisplayOrder();

      return prisma.guide.create({
         data: {
            ...data,
            displayOrder: nextDisplayOrder,
         },
      });
   }

   /**
    * Gets guides with filters and pagination.
    *
    * @param filters - Guide filters.
    * @param skip - Number of guides to skip.
    * @param take - Number of guides to fetch.
    * @returns Guides and total matching count.
    */
   async findAll(filters?: GuideFilters, skip?: number, take?: number): Promise<PaginatedGuides> {
      const baseWhere = this.buildBaseWhereInput(filters);
      const searchQuery = filters?.search?.trim();

      if (searchQuery) {
         return this.findAllBySearch(baseWhere, searchQuery, skip, take);
      }

      return this.findAndCount(baseWhere, skip, take);
   }

   /**
    * Finds a guide by ID.
    *
    * @param id - Guide ID.
    * @returns Guide, or null if not found.
    */
   async findById(id: number): Promise<Guide | null> {
      return prisma.guide.findUnique({
         where: {
            id,
         },
      });
   }

   /**
    * Updates a guide.
    *
    * @param id - Guide ID.
    * @param data - Guide update data.
    * @returns Updated guide.
    */
   async update(id: number, data: UpdateGuideDto): Promise<Guide> {
      const updateData: Prisma.GuideUpdateInput = {
         ...data,
      };

      return prisma.guide.update({
         where: {
            id,
         },
         data: updateData,
      });
   }

   /**
    * Deletes a guide.
    *
    * @param id - Guide ID.
    * @returns Deleted guide.
    */
   async delete(id: number): Promise<Guide> {
      return prisma.guide.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Gets next guide display order.
    *
    * @returns Next display order.
    */
   private async getNextDisplayOrder(): Promise<number> {
      const latestGuide = await prisma.guide.findFirst({
         orderBy: {
            displayOrder: "desc",
         },
         select: {
            displayOrder: true,
         },
      });

      return (latestGuide?.displayOrder ?? 0) + 1;
   }

   /**
    * Builds base guide filter query.
    *
    * @param filters - Guide filters.
    * @returns Prisma guide where input.
    */
   private buildBaseWhereInput(filters?: GuideFilters): Prisma.GuideWhereInput {
      const where: Prisma.GuideWhereInput = {};

      if (filters?.categoryId && !Number.isNaN(filters.categoryId)) {
         where.categoryId = filters.categoryId;
      }

      return where;
   }

   /**
    * Gets guides by search query.
    *
    * @param baseWhere - Base filter query.
    * @param searchQuery - Search query.
    * @param skip - Number of guides to skip.
    * @param take - Number of guides to fetch.
    * @returns Guides and total matching count.
    */
   private async findAllBySearch(baseWhere: Prisma.GuideWhereInput, searchQuery: string, skip?: number, take?: number): Promise<PaginatedGuides> {
      const keywords = this.extractSearchKeywords(searchQuery);

      if (keywords.length > 0) {
         const strictWhere = this.buildKeywordSearchWhereInput(baseWhere, keywords, "AND");
         const strictResult = await this.findAndCount(strictWhere, skip, take);

         if (strictResult.total > 0) {
            return strictResult;
         }

         const looseWhere = this.buildKeywordSearchWhereInput(baseWhere, keywords, "OR");
         const looseResult = await this.findAndCount(looseWhere, skip, take);

         if (looseResult.total > 0) {
            return looseResult;
         }
      }

      const fallbackWhere = this.buildTextSearchWhereInput(baseWhere, searchQuery);

      return this.findAndCount(fallbackWhere, skip, take);
   }

   /**
    * Extracts useful search keywords.
    *
    * @param searchQuery - Search query.
    * @returns Search keywords.
    */
   private extractSearchKeywords(searchQuery: string): string[] {
      const stopWords = new Set(["how", "to", "can", "i", "do", "the", "a", "an", "is", "my", "your", "we", "us", "me", "should", "would", "could", "will", "shall", "please", "help", "about", "what", "where", "when", "why", "who", "any", "some", "there", "their", "them", "they", "he", "she", "it", "you"]);

      return searchQuery
         .toLowerCase()
         .replace(/[^\w\s]/g, "")
         .split(/\s+/)
         .filter((word) => word.length > 0 && !stopWords.has(word));
   }

   /**
    * Builds keyword search query.
    *
    * @param baseWhere - Base filter query.
    * @param keywords - Search keywords.
    * @param mode - Keyword match mode.
    * @returns Prisma guide where input.
    */
   private buildKeywordSearchWhereInput(baseWhere: Prisma.GuideWhereInput, keywords: string[], mode: "AND" | "OR"): Prisma.GuideWhereInput {
      const keywordConditions = keywords.map((keyword) => this.buildTextSearchWhereInput({}, keyword));

      return {
         ...baseWhere,
         [mode]: keywordConditions,
      };
   }

   /**
    * Builds text search query.
    *
    * @param baseWhere - Base filter query.
    * @param searchText - Search text.
    * @returns Prisma guide where input.
    */
   private buildTextSearchWhereInput(baseWhere: Prisma.GuideWhereInput, searchText: string): Prisma.GuideWhereInput {
      return {
         ...baseWhere,
         OR: [
            {
               question: {
                  contains: searchText,
                  mode: "insensitive",
               },
            },
            {
               answer: {
                  contains: searchText,
                  mode: "insensitive",
               },
            },
         ],
      };
   }

   /**
    * Finds guides and matching count.
    *
    * @param where - Guide filter query.
    * @param skip - Number of guides to skip.
    * @param take - Number of guides to fetch.
    * @returns Guides and total matching count.
    */
   private async findAndCount(where: Prisma.GuideWhereInput, skip?: number, take?: number): Promise<PaginatedGuides> {
      const [guides, total] = await prisma.$transaction([
         prisma.guide.findMany({
            where,
            orderBy: {
               displayOrder: "asc",
            },
            skip,
            take,
         }),
         prisma.guide.count({
            where,
         }),
      ]);

      return {
         guides,
         total,
      };
   }
}
