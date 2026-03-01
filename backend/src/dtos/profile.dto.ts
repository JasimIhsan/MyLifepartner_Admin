import { ProfileSection, UserAnswer } from "@prisma/client";

export interface ProfileSectionDto {
   id: number;
   key: string;
   title: string;
   orderNo: number;
   isPrimary: boolean;
}

export const toProfileSectionDto = (section: ProfileSection): ProfileSectionDto => ({
   id: section.id,
   key: section.key,
   title: section.title,
   orderNo: section.orderNo,
   isPrimary: section.isPrimary,
});

export interface UserAnswerDto {
   id: number;
   userId: number;
   questionId: number;
   answer: any;
   score: number | null;
   createdAt: Date;
}

export const toUserAnswerDto = (answer: UserAnswer): UserAnswerDto => ({
   id: answer.id,
   userId: answer.userId,
   questionId: answer.questionId,
   answer: answer.answer,
   score: answer.score,
   createdAt: answer.createdAt,
});

export interface ProfileQuestionDto {
   id: number;
   sectionId: number;
   question: string;
   answerType: string;
   options: string[] | null;
   minWords: number | null;
   weight: number;
   isRequired: boolean;
   orderNo: number;
   isActive: boolean;
   sectionTitle?: string;
   answers?: UserAnswerDto[];
}

export const toProfileQuestionDto = (question: any): ProfileQuestionDto => ({
   id: question.id,
   sectionId: question.sectionId,
   question: question.question,
   answerType: question.answerType,
   options: question.options ? (question.options as string[]) : null,
   minWords: question.minWords,
   weight: question.weight,
   isRequired: question.isRequired,
   orderNo: question.orderNo,
   isActive: question.isActive,
   sectionTitle: question.section?.title,
   answers: question.answers ? question.answers.map(toUserAnswerDto) : undefined,
});

export interface ProfileStatusDto {
   profileStatus: string;
   nextAction: string;
}

export const toProfileStatusDto = (profileStatus: string, nextAction: string): ProfileStatusDto => ({
   profileStatus: profileStatus,
   nextAction: nextAction,
});
