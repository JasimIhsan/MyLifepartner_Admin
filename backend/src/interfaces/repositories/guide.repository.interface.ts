import { Guide, Prisma } from "@prisma/client";

export interface IGuideRepository {
   create(data: Prisma.GuideCreateInput): Promise<Guide>;
   findAll(where?: Prisma.GuideWhereInput, skip?: number, take?: number): Promise<{ guides: Guide[]; total: number }>;
   findById(id: number): Promise<Guide | null>;
   update(id: number, data: Prisma.GuideUpdateInput): Promise<Guide>;
   delete(id: number): Promise<Guide>;
}
