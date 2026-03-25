import { Feature, IAdminFeatureService } from "../../interfaces/services/admin.feature.service.interface";

export const SYSTEM_FEATURES: Feature[] = [
   {
      id: 1,
      key: "audio_call",
      name: "Audio Call",
      description: "Enables audio calling capabilities between users.",
   },
   {
      id: 2,
      key: "video_call",
      name: "Video Call",
      description: "Enables video call capabilities within the platform.",
   },
   {
      id: 3,
      key: "send_message",
      name: "Direct Messaging",
      description: "Allows users to send messages to their matches.",
   },
   {
      id: 4,
      key: "profile_blur",
      name: "Profile Privacy (Blur)",
      description: "Feature to blur profile photos for unverified or non-subscribed users.",
   },
   {
      id: 5,
      key: "max_interests",
      name: "Interest Limit",
      description: "Limits the total number of interests a user can send.",
   },
   {
      id: 6,
      key: "max_video_call_minutes",
      name: "Video Call Allowance (Minutes)",
      description: "Total duration allowed for video calls in minutes.",
   },
   {
      id: 7,
      key: "max_audio_call_minutes",
      name: "Audio Call Allowance (Minutes)",
      description: "Total duration allowed for audio calls in minutes.",
   },
   {
      id: 8,
      key: "max_messages",
      name: "Message Allowance",
      description: "Maximum number of messages a user can send in total.",
   },
];

export class AdminFeatureService implements IAdminFeatureService {
   async getAllFeatures(): Promise<Feature[]> {
      return SYSTEM_FEATURES;
   }
}
