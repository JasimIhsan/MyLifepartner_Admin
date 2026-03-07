import { SwipeAction } from "@prisma/client";

export interface MatchRecommendationItem {
   id: number;
   name: string;
   age: number;
   heightCm: number | null;
   city: string | null;
   religion: string | null;
   occupation: string | null;
   matchPercentage: number;
   compatibilityHighlights: string[];
   images: Array<{ imageUrl: string; isPrimary: boolean }>;
}

export interface SwipeInput {
   userId: number;
   targetProfileId: number;
   action: SwipeAction;
}

export interface IMatchService {
   getRecommendations(userId: number): Promise<MatchRecommendationItem[]>;
   swipeProfile(input: SwipeInput): Promise<void>;
}
