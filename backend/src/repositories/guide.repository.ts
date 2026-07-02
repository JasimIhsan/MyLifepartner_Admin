import prisma from "@/config/prisma";
import { Guide, Prisma } from "@prisma/client";
import { IGuideRepository } from "../interfaces/repositories/guide.repository.interface";

export class GuideRepository implements IGuideRepository {
   async create(data: Prisma.GuideCreateInput): Promise<Guide> {
      const maxGuide = await prisma.guide.findFirst({
         orderBy: { displayOrder: "desc" },
         select: { displayOrder: true },
      });
      const nextOrder = (maxGuide?.displayOrder || 0) + 1;

      return prisma.guide.create({
         data: {
            ...data,
            displayOrder: nextOrder,
         },
      });
   }

   async findAll(where?: Prisma.GuideWhereInput, skip?: number, take?: number): Promise<{ guides: Guide[]; total: number }> {
      const [guides, total] = await prisma.$transaction([
         prisma.guide.findMany({
            where,
            orderBy: { displayOrder: "asc" },
            skip,
            take,
         }),
         prisma.guide.count({ where }),
      ]);
      return { guides, total };
   }

   async findById(id: number): Promise<Guide | null> {
      return prisma.guide.findUnique({ where: { id } });
   }

   async update(id: number, data: Prisma.GuideUpdateInput): Promise<Guide> {
      return prisma.guide.update({ where: { id }, data });
   }

   async delete(id: number): Promise<Guide> {
      return prisma.guide.delete({ where: { id } });
   }
}
