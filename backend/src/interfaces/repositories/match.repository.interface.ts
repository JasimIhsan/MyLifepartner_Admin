import { InteractionState, SwipeAction } from "../services/match.service.interface";

export interface SwipeNotificationContext {
   swiperUserId: number;
   swiperName: string;
   targetUserId: number;
   targetName: string;
   isMutualMatch: boolean;
}

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
   getViewerPrivacyStatus(userId: number): Promise<boolean>;
   deleteSwipe(userId: number, targetProfileId: number): Promise<boolean>;
   getSwipeNotificationContext(userId: number, targetProfileId: number): Promise<SwipeNotificationContext | null>;
}

export interface CandidateProfile {
   id: number;
   interactionState?: InteractionState;
   isBlocked?: boolean;
   userId: number;
   name: string | null;
   isVerified: boolean;
   dateOfBirth: Date | null;
   maritalStatus: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   motherTongue: string | null;
   highestEducation: string | null;
   occupation: string | null;
   bio: string | null;
   gender: string | null;
   privacyEnabled: boolean;
   blurredImageUrl: string | null;
   images: Array<{ id: number; imageUrl: string; isPrimary: boolean }>;
   answers: UserAnswerData[];
   createdAt: Date;
   lastLoginAt: Date;
}

export interface UserPreferenceData {
   ageFrom: number | null;
   ageTo: number | null;
   motherTongue: string[];
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
