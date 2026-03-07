import { Prisma, ProfileQuestion, ProfileSection } from "@prisma/client";

export interface IQuestionnaireRepository {
   // Sections
   createSection(data: Prisma.ProfileSectionCreateInput): Promise<ProfileSection>;
   getSectionByKey(key: string): Promise<ProfileSection | null>;
   getSectionById(id: number): Promise<(ProfileSection & { _count: { questions: number } }) | null>;
   getSectionsWithQuestions(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]>;
   updateSection(id: number, data: Prisma.ProfileSectionUpdateInput): Promise<ProfileSection>;
   deleteSection(id: number): Promise<ProfileSection>;
   reorderSections(orderedIds: number[]): Promise<ProfileSection[]>;

   // Questions
   getQuestionById(id: number): Promise<ProfileQuestion | null>;
   getQuestionByIdWithAnswersCount(id: number): Promise<(ProfileQuestion & { _count: { answers: number } }) | null>;
   createQuestion(data: Prisma.ProfileQuestionUncheckedCreateInput): Promise<ProfileQuestion>;
   updateQuestion(id: number, data: Prisma.ProfileQuestionUpdateInput): Promise<ProfileQuestion>;
   deleteQuestion(id: number): Promise<ProfileQuestion>;
   reorderQuestions(sectionId: number, orderedIds: number[]): Promise<ProfileQuestion[]>;
}
