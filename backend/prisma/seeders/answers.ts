import { AnswerType, PrismaClient } from "@prisma/client";

export async function seedProfileData(prisma: PrismaClient) {
   console.log("Seeding profile data (sections and questions)...");

   // ============================================================
   // 1. Identity & Seriousness Verification
   // ============================================================
   const section1 = await prisma.profileSection.upsert({
      where: { key: "identity_seriousness" },
      update: { title: "Identity & Seriousness Verification", orderNo: 1, isPrimary: true },
      create: {
         key: "identity_seriousness",
         title: "Identity & Seriousness Verification",
         orderNo: 1,
         isPrimary: true,
      },
   });

   // Upsert questions individually if they already exist
   const questions = [
      {
         question: "Why are you joining LP at this stage of your life?",
         answerType: AnswerType.SINGLE_CHOICE,
         options: ["Ready to settle down", "Looking for a life partner", "Tired of casual dating", "Family pressure / Recommendation", "Recently single and want something serious", "Want companionship and commitment"],
         orderNo: 1,
         isRequired: true,
         isActive: true,
      },
   ];

   for (const q of questions) {
      // Find if question already exists in this section
      const existing = await prisma.profileQuestion.findFirst({
         where: { 
            sectionId: section1.id,
            question: q.question 
         }
      });

      if (!existing) {
         await prisma.profileQuestion.create({
            data: {
               ...q,
               sectionId: section1.id,
            }
         });
      }
   }

   console.log("Profile data seeded successfully!");
}
