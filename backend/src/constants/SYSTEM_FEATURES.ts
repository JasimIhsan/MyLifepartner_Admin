import { FeatureKey } from "../enums/feature-key.enum";
import { Feature } from "@/interfaces/services/admin.feature.service.interface";

export const SYSTEM_FEATURES: Feature[] = [
   {
      id: 1,
      key: FeatureKey.AUDIO_CALL,
      name: "Audio Call",
      description: "Enables audio calling capabilities between users.",
   },
   {
      id: 2,
      key: FeatureKey.VIDEO_CALL,
      name: "Video Call",
      description: "Enables video call capabilities within the platform.",
   },
   {
      id: 3,
      key: FeatureKey.SEND_MESSAGE,
      name: "Direct Messaging",
      description: "Allows users to send messages to their matches.",
   },
   {
      id: 4,
      key: FeatureKey.PROFILE_BLUR,
      name: "Profile Privacy (Blur)",
      description: "Feature to blur profile photos for unverified or non-subscribed users.",
   },
   {
      id: 5,
      key: FeatureKey.MAX_INTERESTS,
      name: "Interest Limit",
      description: "Limits the total number of interests a user can send.",
   },
   {
      id: 6,
      key: FeatureKey.MAX_VIDEO_CALL_MINUTES,
      name: "Video Call Allowance (Minutes)",
      description: "Total duration allowed for video calls in minutes.",
   },
   {
      id: 7,
      key: FeatureKey.MAX_AUDIO_CALL_MINUTES,
      name: "Audio Call Allowance (Minutes)",
      description: "Total duration allowed for audio calls in minutes.",
   },
   {
      id: 8,
      key: FeatureKey.MAX_MESSAGES,
      name: "Message Allowance",
      description: "Maximum number of messages a user can send in total.",
   },
];
