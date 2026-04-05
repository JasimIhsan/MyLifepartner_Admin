import prisma from "@/config/prisma";
import { ImageAssets, ImageAssetsSection, Prisma } from "@prisma/client";
import { IImageAssetRepository } from "../interfaces/repositories/image-asset.repository.interface";

export class ImageAssetRepository implements IImageAssetRepository {
   async create(data: Prisma.ImageAssetsCreateInput): Promise<ImageAssets> {
      return prisma.imageAssets.create({ data });
   }

   async findAll(where?: Prisma.ImageAssetsWhereInput, skip?: number, take?: number): Promise<{ assets: ImageAssets[]; total: number }> {
      const [assets, total] = await prisma.$transaction([
         prisma.imageAssets.findMany({
            where,
            orderBy: { displayOrder: "asc" },
            skip,
            take,
         }),
         prisma.imageAssets.count({ where }),
      ]);
      return { assets, total };
   }

   async findById(id: number): Promise<ImageAssets | null> {
      return prisma.imageAssets.findUnique({ where: { id } });
   }

   async findBySection(section: ImageAssetsSection, isActive: boolean = true): Promise<ImageAssets[]> {
      return prisma.imageAssets.findMany({
         where: { section, isActive },
         orderBy: { displayOrder: "asc" },
      });
   }

   async update(id: number, data: Prisma.ImageAssetsUpdateInput): Promise<ImageAssets> {
      return prisma.imageAssets.update({ where: { id }, data });
   }

   async delete(id: number): Promise<ImageAssets> {
      return prisma.imageAssets.delete({ where: { id } });
   }
}
