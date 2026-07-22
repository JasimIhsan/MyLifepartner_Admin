import { PrismaClient } from "@prisma/client";

export async function seedSubscriptionPlans(prisma: PrismaClient) {
   console.log("Seeding subscription plans...");

   // 1) Seed Free Plan
   await prisma.subscriptionPlan.upsert({
      where: { name: "FREE" },
      update: {
         price: 0,
         durationDays: 36500, // ~100 years
         isActive: true,
         isMostPopular: false,
         description: "Free basic plan",
      },
      create: {
         name: "FREE",
         price: 0,
         durationDays: 36500, // ~100 years
         isActive: true,
         isMostPopular: false,
         description: "Free basic plan",
      },
   });

   // 2) Seed Premium Plan
   await prisma.subscriptionPlan.upsert({
      where: { name: "PREMIUM" },
      update: {
         price: 999,
         durationDays: 30,
         isActive: true,
         isMostPopular: true,
         description: "Unlock all premium features, unlimited interest requests, video calls, and priority matching.",
         storeProductId: "com.premiumglobalcorp.lifepartneragain.premium.monthly",
      },
      create: {
         name: "PREMIUM",
         price: 999,
         durationDays: 30,
         isActive: true,
         isMostPopular: true,
         description: "Unlock all premium features, unlimited interest requests, video calls, and priority matching.",
         storeProductId: "com.premiumglobalcorp.lifepartneragain.premium.monthly",
      },
   });

   console.log("Subscription plans seeded successfully!");
}
