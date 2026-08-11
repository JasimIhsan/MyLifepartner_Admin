export interface TransactionInterface {
   id: number;
   userId: number;
   planId: number | null;
   status: string;
   amount: number | null;
   currency: string | null;
   revenueCatEventId: string | null;
   originalTransactionId: string | null;
   store: string | null;
   environment: string | null;
   createdAt: string;
   updatedAt: string;
   user: {
      email: string;
      profile?: {
         name: string | null;
      } | null;
   };
   plan: {
      name: string;
   } | null;
}
