import { SwipeAction } from "@prisma/client";

export enum InteractionState {
   NONE = "NONE",
   INTEREST_SENT = "INTEREST_SENT",
   INTEREST_RECEIVED = "INTEREST_RECEIVED",
   MATCHED = "MATCHED",
}

export interface MatchRecommendationItem {
   id: number;
   userId: number;
   name: string;
   age: number;
   isVerified: boolean;
   heightCm: number | null;
   city: string | null;
   country: string | null;
   occupation: string | null;
   maritalStatus: string | null;
   matchPercentage: number;
   compatibilityHighlights: string[];
   images: Array<{ imageUrl: string; isPrimary: boolean }>;
   interactionState: InteractionState;
   createdAt: Date;
   lastLoginAt: Date;
}

export interface SwipeInput {
   userId: number;
   targetProfileId: number;
   action: SwipeAction;
}

export interface ProfileDetail {
   id: number;
   userId: number;
   name: string;
   age: number;
   gender: string | null;
   heightCm: number | null;
   maritalStatus: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   motherTongue: string | null;
   highestEducation: string | null;
   occupation: string | null;
   bio: string | null;
   matchPercentage: number;
   compatibilityHighlights: string[];
   images: Array<{ imageUrl: string; isPrimary: boolean }>;
   interactionState: InteractionState;
   createdAt: Date;
   lastLoginAt: Date;
   isVerified: boolean;
}

export interface IMatchService {
   getRecommendations(userId: number): Promise<MatchRecommendationItem[]>;
   swipeProfile(input: SwipeInput): Promise<void>;
   getProfileDetail(userId: number, profileId: number): Promise<ProfileDetail | null>;
   getSentInterests(userId: number): Promise<MatchRecommendationItem[]>;
   getReceivedInterests(userId: number): Promise<MatchRecommendationItem[]>;
   getMutualMatches(userId: number): Promise<MatchRecommendationItem[]>;
}
