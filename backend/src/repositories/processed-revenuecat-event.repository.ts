import prisma from "@/config/prisma";
import { IProcessedRevenueCatEventRepository } from "@/interfaces/repositories/processed-revenuecat-event.repository.interface";

export class ProcessedRevenueCatEventRepository implements IProcessedRevenueCatEventRepository {
   /**
    * Checks if a RevenueCat event is already processed.
    *
    * @param eventId - RevenueCat event ID.
    * @returns True if the event is already processed, otherwise false.
    */
   async hasProcessedEvent(eventId: string): Promise<boolean> {
      const event = await prisma.processedRevenueCatEvent.findUnique({
         where: {
            id: eventId,
         },
      });

      return Boolean(event);
   }

   /**
    * Marks a RevenueCat event as processed.
    *
    * @param eventId - RevenueCat event ID.
    * @param type - RevenueCat event type.
    * @returns Nothing.
    */
   async markEventProcessed(eventId: string, type: string): Promise<void> {
      await prisma.processedRevenueCatEvent.create({
         data: {
            id: eventId,
            type,
         },
      });
   }
}
