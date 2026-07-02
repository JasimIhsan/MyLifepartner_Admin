import { UserFeature } from "@prisma/client";

export enum UserFeatureMaxKey {
   MAX_INTERESTS = 'maxInterests',
   MAX_VIDEO_CALL_MINUTES = 'maxVideoCallMinutes',
   MAX_AUDIO_CALL_MINUTES = 'maxAudioCallMinutes',
   MAX_MESSAGES = 'maxMessages'
}

export enum UserFeatureUsageKey {
   INTERESTS = 'interests',
   VIDEO_CALL_MINUTES = 'videoCallMinutes',
   AUDIO_CALL_MINUTES = 'audioCallMinutes',
   MESSAGES = 'messages'
}

export const hasFeature = (
   features: UserFeature, 
   featureMaxKey: UserFeatureMaxKey
): boolean => {
   return (features[featureMaxKey] as number) > 0;
};

export const hasReachedLimit = (
   features: UserFeature, 
   featureMaxKey: UserFeatureMaxKey,
   currentKey: UserFeatureUsageKey
): boolean => {
   return (features[currentKey] as number) >= (features[featureMaxKey] as number);
};
