import { PrismaClient } from "@prisma/client";

export async function seedSubscriptionPlans(prisma: PrismaClient) {
   console.log("Seeding subscription plans...");

   // Seed Free Plan
   await prisma.subscriptionPlan.upsert({
      where: { name: "FREE" },
      update: {},
      create: {
         name: "FREE",
         price: 0,
         durationDays: 36500, // ~100 years
         isActive: true,
      },
   });

   console.log("Subscription plans seeded successfully!");
}
