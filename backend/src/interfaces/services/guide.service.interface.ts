import { Guide, Prisma } from "@prisma/client";

export interface GuideFilters {
   categoryId?: number;
   search?: string;
   page?: number;
   limit?: number;
}

export interface IGuideService {
   createGuide(data: Prisma.GuideCreateInput): Promise<Guide>;
   getAllGuides(filters: GuideFilters): Promise<{ guides: Guide[]; total: number }>;
   getGuideById(id: number): Promise<Guide | null>;
   updateGuide(id: number, data: Prisma.GuideUpdateInput): Promise<Guide>;
   deleteGuide(id: number): Promise<Guide>;
}
