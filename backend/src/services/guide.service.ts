import { Guide, GuideFilters, IGuideService } from "@/interfaces/services/guide.service.interface";
import { CreateGuideDto, UpdateGuideDto } from "@/dtos/guide.input.dto";
import { IGuideRepository } from "@/interfaces/repositories/guide.repository.interface";

export class GuideService implements IGuideService {
   constructor(private readonly guideRepository: IGuideRepository) {}

   /**
    * Creates a new guide
    * @param data - The DTO containing the guide details
    * @returns The created Guide object
    */
   async createGuide(data: CreateGuideDto): Promise<Guide> {
      return this.guideRepository.create(data) as unknown as Guide;
   }

   /**
    * Retrieves a paginated list of guides based on the provided filters
    * @param filters - Filtering criteria (e.g., categoryId, search, pagination)
    * @returns An object containing the list of guides and total count
    */
   async getAllGuides(filters: GuideFilters): Promise<{ guides: Guide[]; total: number }> {
      const { page, limit } = filters;
      let skip: number | undefined;
      let take: number | undefined;
      if (page && limit) {
         skip = (page - 1) * limit;
         take = limit;
      }
      const result = await this.guideRepository.findAll(filters, skip, take);
      return {
         guides: result.guides as unknown as Guide[],
         total: result.total,
      };
   }

   /**
    * Retrieves a guide by its ID
    * @param id - The ID of the guide
    * @returns The Guide object if found, otherwise null
    */
   async getGuideById(id: number): Promise<Guide | null> {
      return this.guideRepository.findById(id) as unknown as Guide | null;
   }

   /**
    * Updates an existing guide
    * @param id - The ID of the guide to update
    * @param data - The DTO containing updated fields
    * @returns The updated Guide object
    */
   async updateGuide(id: number, data: UpdateGuideDto): Promise<Guide> {
      return this.guideRepository.update(id, data) as unknown as Guide;
   }

   /**
    * Deletes a guide by its ID
    * @param id - The ID of the guide to delete
    * @returns The deleted Guide object
    */
   async deleteGuide(id: number): Promise<Guide> {
      return this.guideRepository.delete(id) as unknown as Guide;
   }
}
