import { CreateGuideDto, UpdateGuideDto } from "@/dtos/guide.input.dto";

export interface Guide {
   id: number;
   question: string;
   answer: string;
   categoryId: number;
   bullets: string[];
   displayOrder: number;
   createdAt: Date;
   updatedAt: Date;
}

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
