import { Guide } from "@prisma/client";
import { CreateGuideDto, UpdateGuideDto } from "@/dtos/guide.input.dto";
import { GuideFilters } from "@/interfaces/services/guide.service.interface";

export interface IGuideRepository {
   create(data: CreateGuideDto): Promise<Guide>;
   findAll(filters?: GuideFilters, skip?: number, take?: number): Promise<{ guides: Guide[]; total: number }>;
   findById(id: number): Promise<Guide | null>;
   update(id: number, data: UpdateGuideDto): Promise<Guide>;
   delete(id: number): Promise<Guide>;
}
