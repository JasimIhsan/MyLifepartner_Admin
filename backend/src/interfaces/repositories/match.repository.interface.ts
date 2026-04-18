import { SwipeAction } from "@prisma/client";
import { InteractionState } from "../services/match.service.interface";

export interface IMatchRepository {
   getCandidateProfiles(currentUserId: number, excludedProfileIds: number[]): Promise<CandidateProfile[]>;
   getUserPreference(userId: number): Promise<UserPreferenceData | null>;
   getUserAnswers(userId: number): Promise<UserAnswerData[]>;
   getLikedProfiles(userId: number): Promise<CandidateProfile[]>;
   getSentInterests(userId: number): Promise<CandidateProfile[]>;
   getReceivedInterests(userId: number): Promise<CandidateProfile[]>;
   getMutualMatches(userId: number): Promise<CandidateProfile[]>;
   getSwipedProfileIds(userId: number): Promise<SwipedProfile[]>;
   recordSwipe(userId: number, targetProfileId: number, action: SwipeAction): Promise<void>;
   getProfileById(currentUserId: number, profileId: number): Promise<CandidateProfile | null>;
}

export interface CandidateProfile {
   id: number;
   interactionState?: InteractionState;
   userId: number;
   name: string | null;
   isVerified: boolean;
   dateOfBirth: Date | null;
   heightCm: number | null;
   maritalStatus: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   religion: string | null;
   motherTongue: string | null;
   highestEducation: string | null;
   occupation: string | null;
   annualIncome: number | null;
   bio: string | null;
   gender: string | null;
   images: Array<{ imageUrl: string; isPrimary: boolean }>;
   answers: UserAnswerData[];
   createdAt: Date;
   lastLoginAt: Date;
}

export interface UserPreferenceData {
   ageFrom: number | null;
   ageTo: number | null;
   heightFrom: number | null;
   heightTo: number | null;
   religion: string[];
   motherTongue: string[];
   highestEducation: string[];
   occupation: string[];
   annualIncomeFrom: number | null;
   annualIncomeTo: number | null;
}

export interface UserAnswerData {
   questionId: number;
   answer: import("@prisma/client").Prisma.JsonValue;
   score: number | null;
}

export interface SwipedProfile {
   targetProfileId: number;
   action: SwipeAction;
}
