export enum SwipeAction {
   LEFT = "LEFT",
   RIGHT = "RIGHT",
   UP = "UP",
}

export enum InteractionState {
   NONE = "NONE",
   INTEREST_SENT = "INTEREST_SENT",
   INTEREST_RECEIVED = "INTEREST_RECEIVED",
   MATCHED = "MATCHED",
}

export interface ProfileImageResponse {
   id: number;
   imageId: number;
   imageUrl: string;
   presignedImageUrl: string;
   isPrimary: boolean;
   isBlurred?: boolean;
}

export interface MatchRecommendationItem {
   id: number;
   userId: number;
   name: string;
   age: number;
   isVerified: boolean;
   isFoundingMember: boolean;
   city: string | null;
   country: string | null;
   occupation: string | null;
   maritalStatus: string | null;
   matchPercentage: number;
   compatibilityHighlights: string[];
   images: ProfileImageResponse[];
   interactionState: InteractionState;
   createdAt: Date;
   lastLoginAt: Date;
   viewerPrivacyEnabled?: boolean;
   targetPrivacyEnabled?: boolean;
   imageAccessRequestStatus?: string | null;
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
   maritalStatus: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   motherTongue: string | null;
   highestEducation: string | null;
   occupation: string | null;
   bio: string | null;
   childrenStatus?: string | null;
   drinkingHabit?: string | null;
   emotionalReadiness?: string | null;
   languages?: string[];
   lookingFor?: string | null;
   relationshipTimeline?: string | null;
   smokingHabit?: string | null;
   matchPercentage: number;
   compatibilityHighlights: string[];
   images: ProfileImageResponse[];
   interactionState: InteractionState;
   createdAt: Date;
   lastLoginAt: Date;
   isVerified: boolean;
   isFoundingMember: boolean;
   viewerPrivacyEnabled?: boolean;
   targetPrivacyEnabled?: boolean;
   imageAccessRequestStatus?: string | null;
}

export interface IMatchService {
   getRecommendations(userId: number): Promise<MatchRecommendationItem[]>;
   swipeProfile(input: SwipeInput): Promise<void>;
   getProfileDetail(userId: number, profileId: number): Promise<ProfileDetail | null>;
   getSentInterests(userId: number): Promise<MatchRecommendationItem[]>;
   getReceivedInterests(userId: number): Promise<MatchRecommendationItem[]>;
   getMutualMatches(userId: number): Promise<MatchRecommendationItem[]>;
   cancelSwipeInterest(userId: number, targetProfileId: number): Promise<void>;
}
