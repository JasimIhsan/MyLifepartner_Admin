import { Guide } from "@prisma/client";
import { CreateGuideDto, UpdateGuideDto } from "@/dtos/guide.input.dto";

export interface GuideFilters {
   categoryId?: number;
   search?: string;
   page?: number;
   limit?: number;
}

export interface IGuideService {
   createGuide(data: CreateGuideDto): Promise<Guide>;
   getAllGuides(filters: GuideFilters): Promise<{ guides: Guide[]; total: number }>;
   getGuideById(id: number): Promise<Guide | null>;
   updateGuide(id: number, data: UpdateGuideDto): Promise<Guide>;
   deleteGuide(id: number): Promise<Guide>;
}
