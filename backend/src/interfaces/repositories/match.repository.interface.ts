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
   getUserMatchProfile(userId: number): Promise<MatchProfileData | null>;
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
   isFoundingMember: boolean;
   jobId: number | null;
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
   childrenStatus: string | null;
   drinkingHabit: string | null;
   emotionalReadiness: string | null;
   languages: string[];
   lookingFor: string | null;
   relationshipTimeline: string | null;
   smokingHabit: string | null;
   privacyEnabled: boolean;
   blurredImageUrl: string | null;
   images: Array<{ id: number; imageUrl: string; isPrimary: boolean }>;
   createdAt: Date;
   lastLoginAt: Date;
}

export interface UserPreferenceData {
   ageFrom: number | null;
   ageTo: number | null;
   maritalStatus: string[];
   motherTongue: string[];
}

export interface MatchProfileData {
   jobId: number | null;
   dateOfBirth: Date | null;
   maritalStatus: string | null;
   city: string | null;
   state: string | null;
   country: string | null;
   motherTongue: string | null;
   highestEducation: string | null;
   occupation: string | null;
   childrenStatus: string | null;
   drinkingHabit: string | null;
   emotionalReadiness: string | null;
   languages: string[];
   lookingFor: string | null;
   smokingHabit: string | null;
}

export interface SwipedProfile {
   targetProfileId: number;
   action: SwipeAction;
}
