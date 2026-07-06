export interface IProcessedRevenueCatEventRepository {
   hasProcessedEvent(eventId: string): Promise<boolean>;
   markEventProcessed(eventId: string, type: string): Promise<void>;
}
