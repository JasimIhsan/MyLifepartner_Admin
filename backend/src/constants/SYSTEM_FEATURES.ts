import { Feature } from "@/interfaces/services/admin.feature.service.interface";
import { FeatureKey } from "../enums/feature-key.enum";

export const SYSTEM_FEATURES: Feature[] = [
   {
      id: 1,
      key: FeatureKey.MAX_INTERESTS,
      name: "Interest Limit",
      boolean: false,
      description: "Express your interest and connect with potential partners.",
   },
   {
      id: 2,
      key: FeatureKey.MAX_VIDEO_CALL_MINUTES,
      name: "Video Call Allowance (Minutes)",
      boolean: false,
      description: "Enjoy face-to-face video calls directly within the app.",
   },
   {
      id: 3,
      key: FeatureKey.MAX_AUDIO_CALL_MINUTES,
      name: "Audio Call Allowance (Minutes)",
      boolean: false,
      description: "Connect via secure voice calls without sharing your phone number.",
   },
   {
      id: 4,
      key: FeatureKey.MAX_MESSAGES,
      name: "Message Allowance",
      boolean: false,
      description: "Send direct messages to matches and start meaningful conversations.",
   },
];
