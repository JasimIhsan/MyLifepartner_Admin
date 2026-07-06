export enum AnswerType {
   TEXT = "TEXT",
   SINGLE_CHOICE = "SINGLE_CHOICE",
   MULTI_CHOICE = "MULTI_CHOICE",
   RATING = "RATING",
   BOOLEAN = "BOOLEAN",
}

export interface ProfileSection {
   id: number;
   key: string;
   title: string;
   orderNo: number;
   isPrimary: boolean;
}

export interface ProfileQuestion {
   id: number;
   sectionId: number;
   question: string;
   answerType: AnswerType;
   options: unknown | null;
   minWords: number | null;
   weight: number;
   isRequired: boolean;
   orderNo: number;
   isActive: boolean;
}

export interface IAdminQuestionnaireService {
   // Sections
   createSection(data: { key: string; title: string; orderNo?: number; isPrimary?: boolean }): Promise<ProfileSection>;
   getSections(): Promise<(ProfileSection & { questions: ProfileQuestion[] })[]>;
   updateSection(id: number, data: { key?: string; title?: string; isPrimary?: boolean }): Promise<ProfileSection>;
   deleteSection(id: number): Promise<ProfileSection>;
   reorderSections(orderedIds: number[]): Promise<ProfileSection[]>;

   // Questions
   createQuestion(sectionId: number, data: { question: string; answerType: AnswerType; options?: unknown; minWords?: number; weight?: number; isRequired?: boolean; orderNo?: number; isActive?: boolean }): Promise<ProfileQuestion>;
   updateQuestion(id: number, data: { question?: string; answerType?: AnswerType; options?: unknown; minWords?: number; weight?: number; isRequired?: boolean }): Promise<ProfileQuestion>;
   toggleQuestionActive(id: number): Promise<ProfileQuestion>;
   deleteQuestion(id: number): Promise<ProfileQuestion>;
   reorderQuestions(sectionId: number, orderedIds: number[]): Promise<ProfileQuestion[]>;
}
