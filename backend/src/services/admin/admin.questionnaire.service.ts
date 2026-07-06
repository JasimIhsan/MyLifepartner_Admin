import { IQuestionnaireRepository } from "@/interfaces/repositories/questionnaire.repository.interface";
import { IAdminQuestionnaireService } from "@/interfaces/services/admin.questionnaire.service.interface";
import { ApiError } from "@/utils/ApiError";
import { AnswerType, ProfileQuestion, ProfileSection } from "@/interfaces/services/admin.questionnaire.service.interface";

type CreateSectionData = {
   key: string;
   title: string;
   orderNo?: number;
   isPrimary?: boolean;
};

type UpdateSectionData = {
   key?: string;
   title?: string;
   isPrimary?: boolean;
};

type CreateQuestionData = {
   question: string;
   answerType: AnswerType;
   options?: unknown;
   minWords?: number;
   weight?: number;
   isRequired?: boolean;
   orderNo?: number;
   isActive?: boolean;
};

type UpdateQuestionData = {
   question?: string;
   answerType?: AnswerType;
   options?: unknown;
   minWords?: number;
   weight?: number;
   isRequired?: boolean;
};

export class AdminQuestionnaireService implements IAdminQuestionnaireService {
   constructor(private readonly questionnaireRepository: IQuestionnaireRepository) {}

   /**
    * Creates a questionnaire section.
    *
    * @param data - Section creation data.
    * @returns Created section.
    */
   async createSection(data: CreateSectionData): Promise<ProfileSection> {
      await this.ensureSectionKeyIsAvailable(data.key);

      return this.questionnaireRepository.createSection(data) as unknown as ProfileSection;
   }

   /**
    * Gets questionnaire sections with questions.
    *
    * @returns Sections with questions.
    */
   async getSections(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]> {
      return this.questionnaireRepository.getSectionsWithQuestions() as unknown as (ProfileSection & { questions: ProfileQuestion[] })[];
   }

   /**
    * Updates a questionnaire section.
    *
    * @param id - Section ID.
    * @param data - Section update data.
    * @returns Updated section.
    */
   async updateSection(id: number, data: UpdateSectionData): Promise<ProfileSection> {
      if (data.key) {
         await this.ensureSectionKeyIsAvailable(data.key, id);
      }

      return this.questionnaireRepository.updateSection(id, data);
   }

   /**
    * Deletes a questionnaire section.
    *
    * @param id - Section ID.
    * @returns Deleted section.
    */
   async deleteSection(id: number): Promise<ProfileSection> {
      const section = await this.questionnaireRepository.getSectionById(id);

      if (!section) {
         throw new ApiError(404, "Section not found");
      }

      return this.questionnaireRepository.deleteSection(id);
   }

   /**
    * Reorders questionnaire sections.
    *
    * @param orderedIds - Section IDs in new order.
    * @returns Updated sections.
    */
   async reorderSections(orderedIds: number[]): Promise<ProfileSection[]> {
      return this.questionnaireRepository.reorderSections(orderedIds) as unknown as ProfileSection[];
   }

   /**
    * Creates a questionnaire question.
    *
    * @param sectionId - Section ID.
    * @param data - Question creation data.
    * @returns Created question.
    */
   async createQuestion(sectionId: number, data: CreateQuestionData): Promise<ProfileQuestion> {
      await this.ensureSectionExists(sectionId);

      return this.questionnaireRepository.createQuestion({
         ...data,
         sectionId,
      } as unknown as Parameters<typeof this.questionnaireRepository.createQuestion>[0]) as unknown as ProfileQuestion;
   }

   /**
    * Updates a questionnaire question.
    *
    * @param id - Question ID.
    * @param data - Question update data.
    * @returns Updated question.
    */
   async updateQuestion(id: number, data: UpdateQuestionData): Promise<ProfileQuestion> {
      await this.ensureQuestionExists(id);

      return this.questionnaireRepository.updateQuestion(id, data as unknown as Parameters<typeof this.questionnaireRepository.updateQuestion>[1]) as unknown as ProfileQuestion;
   }

   /**
    * Toggles question active status.
    *
    * @param id - Question ID.
    * @returns Updated question.
    */
   async toggleQuestionActive(id: number): Promise<ProfileQuestion> {
      const question = await this.getRequiredQuestion(id);

      return this.questionnaireRepository.updateQuestion(id, {
         isActive: !question.isActive,
      } as unknown as Parameters<typeof this.questionnaireRepository.updateQuestion>[1]) as unknown as ProfileQuestion;
   }

   /**
    * Deletes a questionnaire question.
    *
    * @param id - Question ID.
    * @returns Deleted question.
    */
   async deleteQuestion(id: number): Promise<ProfileQuestion> {
      const question = await this.questionnaireRepository.getQuestionById(id);

      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return this.questionnaireRepository.deleteQuestion(id) as unknown as ProfileQuestion;
   }

   /**
    * Reorders questions inside a section.
    *
    * @param sectionId - Section ID.
    * @param orderedIds - Question IDs in new order.
    * @returns Updated questions.
    */
   async reorderQuestions(sectionId: number, orderedIds: number[]): Promise<ProfileQuestion[]> {
      await this.ensureSectionExists(sectionId);

      return this.questionnaireRepository.reorderQuestions(sectionId, orderedIds) as unknown as ProfileQuestion[];
   }

   /**
    * Checks section key availability.
    *
    * @param key - Section key.
    * @param ignoreSectionId - Optional section ID to ignore.
    * @returns Nothing.
    */
   private async ensureSectionKeyIsAvailable(key: string, ignoreSectionId?: number): Promise<void> {
      const existingSection = await this.questionnaireRepository.getSectionByKey(key);

      if (existingSection && existingSection.id !== ignoreSectionId) {
         throw new ApiError(409, `Section with key '${key}' already exists`);
      }
   }

   /**
    * Ensures section exists.
    *
    * @param sectionId - Section ID.
    * @returns Nothing.
    */
   private async ensureSectionExists(sectionId: number): Promise<void> {
      const section = await this.questionnaireRepository.getSectionById(sectionId);

      if (!section) {
         throw new ApiError(404, "Section not found");
      }
   }

   /**
    * Ensures question exists.
    *
    * @param questionId - Question ID.
    * @returns Nothing.
    */
   private async ensureQuestionExists(questionId: number): Promise<void> {
      await this.getRequiredQuestion(questionId);
   }

   /**
    * Gets required question.
    *
    * @param questionId - Question ID.
    * @returns Question.
    */
   private async getRequiredQuestion(questionId: number): Promise<ProfileQuestion> {
      const question = await this.questionnaireRepository.getQuestionById(questionId);

      if (!question) {
         throw new ApiError(404, "Question not found");
      }

      return question as unknown as ProfileQuestion;
   }
}
