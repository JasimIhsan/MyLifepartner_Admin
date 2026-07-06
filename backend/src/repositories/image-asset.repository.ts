import prisma from "@/config/prisma";
import { CreateImageAssetDto, ImageAssetFilters, UpdateImageAssetDto } from "@/dtos/image-asset.dto";
import { ImageAssets, ImageAssetsSection, Prisma } from "@prisma/client";
import { IImageAssetRepository } from "../interfaces/repositories/image-asset.repository.interface";

type PaginatedImageAssets = {
   assets: ImageAssets[];
   total: number;
};

export class ImageAssetRepository implements IImageAssetRepository {
   /**
    * Creates an image asset.
    *
    * @param data - Image asset creation data.
    * @returns Created image asset.
    */
   async create(data: CreateImageAssetDto): Promise<ImageAssets> {
      const createData: Prisma.ImageAssetsCreateInput = {
         ...data,
      };

      return prisma.imageAssets.create({
         data: createData,
      });
   }

   /**
    * Gets image assets with filters and pagination.
    *
    * @param filters - Image asset filters.
    * @param skip - Number of assets to skip.
    * @param take - Number of assets to fetch.
    * @returns Image assets and total matching count.
    */
   async findAll(filters?: ImageAssetFilters, skip?: number, take?: number): Promise<PaginatedImageAssets> {
      const where = this.buildImageAssetWhereInput(filters);

      const [assets, total] = await prisma.$transaction([
         prisma.imageAssets.findMany({
            where,
            orderBy: {
               displayOrder: "asc",
            },
            skip,
            take,
         }),
         prisma.imageAssets.count({
            where,
         }),
      ]);

      return {
         assets,
         total,
      };
   }

   /**
    * Finds an image asset by ID.
    *
    * @param id - Image asset ID.
    * @returns Image asset, or null if not found.
    */
   async findById(id: number): Promise<ImageAssets | null> {
      return prisma.imageAssets.findUnique({
         where: {
            id,
         },
      });
   }

   /**
    * Finds image assets by section.
    *
    * @param section - Image asset section.
    * @param isActive - Active status filter.
    * @returns Image assets for the section.
    */
   async findBySection(section: ImageAssetsSection, isActive: boolean = true): Promise<ImageAssets[]> {
      return prisma.imageAssets.findMany({
         where: {
            section,
            isActive,
         },
         orderBy: {
            displayOrder: "asc",
         },
      });
   }

   /**
    * Updates an image asset.
    *
    * @param id - Image asset ID.
    * @param data - Image asset update data.
    * @returns Updated image asset.
    */
   async update(id: number, data: UpdateImageAssetDto): Promise<ImageAssets> {
      const updateData: Prisma.ImageAssetsUpdateInput = {
         ...data,
      };

      return prisma.imageAssets.update({
         where: {
            id,
         },
         data: updateData,
      });
   }

   /**
    * Deletes an image asset.
    *
    * @param id - Image asset ID.
    * @returns Deleted image asset.
    */
   async delete(id: number): Promise<ImageAssets> {
      return prisma.imageAssets.delete({
         where: {
            id,
         },
      });
   }

   /**
    * Builds image asset filter query.
    *
    * @param filters - Image asset filters.
    * @returns Prisma image asset where input.
    */
   private buildImageAssetWhereInput(filters?: ImageAssetFilters): Prisma.ImageAssetsWhereInput {
      return {
         ...(filters?.section !== undefined && {
            section: filters.section,
         }),
         ...(filters?.isActive !== undefined && {
            isActive: filters.isActive,
         }),
      };
   }
}
