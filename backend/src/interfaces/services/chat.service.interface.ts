export enum MessageType {
   TEXT = "TEXT",
   IMAGE = "IMAGE",
   AUDIO = "AUDIO",
   VIDEO = "VIDEO",
   CALL_LOG = "CALL_LOG",
}

export interface ChatMessage {
   id: number;
   conversationId: number;
   senderId: number;
   content: string;
   messageType: MessageType;
   zegoMessageId: string | null;
   createdAt: Date;
}
