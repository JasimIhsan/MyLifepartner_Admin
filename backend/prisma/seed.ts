import { PrismaPg } from "@prisma/adapter-pg";
import { AnswerType, PrismaClient } from "@prisma/client";
import * as dotenv from "dotenv";
import { Pool } from "pg";

dotenv.config();

const connectionString = `${process.env.DATABASE_URL}`;

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
   console.log("Start seeding...");

   try {
      // Clean up existing questions to avoid duplicates/conflicts if re-seeding
      // await prisma.userAnswer.deleteMany({});
      // await prisma.profileQuestion.deleteMany({});
      // await prisma.profileSection.deleteMany({});
      // Commented out delete to be safe, using upsert/skipDuplicates logic.

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

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section1.id,
               question: "Why are you joining LP at this stage of your life?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: [
                  "Ready to settle down",
                  "Looking for a life partner",
                  "Tired of casual dating",
                  "Family pressure / Recommendation",
                  "Recently single and want something serious",
                  "Want companionship and commitment",
               ],
               orderNo: 1,
               isRequired: true,
            },
            {
               sectionId: section1.id,
               question: "Are you looking for:",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Marriage", "Long-term partnership", "Companionship leading to commitment", "Still exploring"],
               orderNo: 2,
               isRequired: true,
            },
            {
               sectionId: section1.id,
               question: "Have you been married before?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["No", "Divorced", "Widowed", "Separated"],
               orderNo: 3,
               isRequired: true,
            },
            {
               sectionId: section1.id,
               question: "If divorced or widowed, how long have you been single?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: [
                  "Less than 6 months",
                  "6 months – 1 year",
                  "1 – 2 years",
                  "2 – 5 years",
                  "More than 5 years",
               ],
               // usage: Logic in frontend can show/hide based on previous answer
               orderNo: 4,
               isRequired: false, // Conditional
            },
            {
               sectionId: section1.id,
               question: "Do you feel emotionally ready for a committed relationship?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Yes", "Somewhat", "Not sure"],
               orderNo: 5,
               isRequired: true,
            },
            {
               sectionId: section1.id,
               question: "Who knows you are joining this platform?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Close family", "Friends", "No one yet"],
               orderNo: 6,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 2. Emotional Maturity Screening
      // ============================================================
      const section2 = await prisma.profileSection.upsert({
         where: { key: "emotional_maturity" },
         update: { title: "Emotional Maturity Screening", orderNo: 2 },
         create: {
            key: "emotional_maturity",
            title: "Emotional Maturity Screening",
            orderNo: 2,
         },
      });

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section2.id,
               question: "When conflict happens in a relationship, you usually:",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Communicate calmly", "Need time", "Avoid", "Reactive"],
               orderNo: 1,
               isRequired: true,
            },
            {
               sectionId: section2.id,
               question: "Have you done personal growth work after your last relationship?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Therapy", "Self-reflection", "Books", "No"],
               orderNo: 2,
               isRequired: true,
            },
            {
               sectionId: section2.id,
               question: "What did your last relationship teach you?",
               answerType: AnswerType.TEXT,
               minWords: 100,
               orderNo: 3,
               isRequired: true,
            },
            {
               sectionId: section2.id,
               question: "How do you handle disagreements?",
               answerType: AnswerType.TEXT,
               orderNo: 4,
               isRequired: true,
            },
            {
               sectionId: section2.id,
               question: "What is more important?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Being right", "Solving the issue together"],
               orderNo: 5,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 3. Lifestyle & Stability
      // ============================================================
      const section3 = await prisma.profileSection.upsert({
         where: { key: "lifestyle_stability" },
         update: { title: "Lifestyle & Stability", orderNo: 3 },
         create: {
            key: "lifestyle_stability",
            title: "Lifestyle & Stability",
            orderNo: 3,
         },
      });

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section3.id,
               question: "Do you have children?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["No", "Living with me", "Shared custody", "Independent"],
               orderNo: 1,
               isRequired: true,
            },
            {
               sectionId: section3.id,
               question: "Do you want more children?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Yes", "No", "Open"],
               orderNo: 2,
               isRequired: true,
            },
            {
               sectionId: section3.id,
               question: "Work schedule:",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Fixed hours", "Shift", "Self-employed", "Retired"],
               orderNo: 3,
               isRequired: true,
            },
            {
               sectionId: section3.id,
               question: "How do you spend weekends?",
               answerType: AnswerType.TEXT,
               orderNo: 4,
               isRequired: true,
            },
            {
               sectionId: section3.id,
               question: "Social lifestyle:",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Home-oriented", "Balanced", "Highly social"],
               orderNo: 5,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 4. Values & Character
      // ============================================================
      const section4 = await prisma.profileSection.upsert({
         where: { key: "values_character" },
         update: { title: "Values & Character", orderNo: 4 },
         create: {
            key: "values_character",
            title: "Values & Character",
            orderNo: 4,
         },
      });

      // 4.1 Broken down into individual rating questions
      const valuesToRate = ["Honesty", "Loyalty", "Family", "Faith", "Career ambition", "Emotional intelligence", "Health"];
      const ratingQuestions = valuesToRate.map((val, idx) => ({
         sectionId: section4.id,
         question: `Rate importance (1-5): ${val}`,
         answerType: AnswerType.RATING,
         orderNo: idx + 1, // 1 to 7
         isRequired: true,
      }));

      await prisma.profileQuestion.createMany({
         data: [
            ...ratingQuestions,
            {
               sectionId: section4.id,
               question: "What values can you never compromise on?",
               answerType: AnswerType.TEXT,
               orderNo: 8,
               isRequired: true,
            },
            {
               sectionId: section4.id,
               question: "How do you show love in a relationship?",
               answerType: AnswerType.TEXT,
               orderNo: 9,
               isRequired: true,
            },
            {
               sectionId: section4.id,
               question: "How do you want your partner to feel with you?",
               answerType: AnswerType.TEXT,
               orderNo: 10,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 5. Relationship Expectations
      // ============================================================
      const section5 = await prisma.profileSection.upsert({
         where: { key: "relationship_expectations" },
         update: { title: "Relationship Expectations", orderNo: 5 },
         create: {
            key: "relationship_expectations",
            title: "Relationship Expectations",
            orderNo: 5,
         },
      });

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section5.id,
               question: "What does a successful relationship look like to you?",
               answerType: AnswerType.TEXT,
               minWords: 100,
               orderNo: 1,
               isRequired: true,
            },
            {
               sectionId: section5.id,
               question: "What are your deal breakers?",
               answerType: AnswerType.TEXT,
               orderNo: 2,
               isRequired: true,
            },
            {
               sectionId: section5.id,
               question: "How soon would you like to meet in person after connecting?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Weeks", "1–3 months", "Take time"],
               orderNo: 3,
               isRequired: true,
            },
            {
               sectionId: section5.id,
               question: "Would you relocate for the right partner?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Yes", "Maybe", "No"],
               orderNo: 4,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 6. Communication Style
      // ============================================================
      const section6 = await prisma.profileSection.upsert({
         where: { key: "communication_style" },
         update: { title: "Communication Style", orderNo: 6 },
         create: {
            key: "communication_style",
            title: "Communication Style",
            orderNo: 6,
         },
      });

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section6.id,
               question: "Preferred communication",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Calls", "Text", "Video", "In person"],
               orderNo: 1,
               isRequired: true,
            },
            {
               sectionId: section6.id,
               question: "Love language",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Words", "Time", "Acts", "Gifts", "Touch"],
               orderNo: 2,
               isRequired: true,
            },
            {
               sectionId: section6.id,
               question: "How often do you expect communication in a serious relationship?",
               answerType: AnswerType.TEXT,
               orderNo: 3,
               isRequired: true,
            },
         ],
         skipDuplicates: true,
      });

      // ============================================================
      // 7. Safety & Intent Declaration
      // ============================================================
      const section7 = await prisma.profileSection.upsert({
         where: { key: "safety_intent" },
         update: { title: "Safety & Intent Declaration", orderNo: 7 },
         create: {
            key: "safety_intent",
            title: "Safety & Intent Declaration",
            orderNo: 7,
         },
      });

      const intentStatements = ["I am not here for casual dating", "I will treat members with respect", "I understand profile review & moderation", "I agree to meet only in safe public places", "I confirm my information is truthful"];

      const intentQuestions = intentStatements.map((stmt, idx) => ({
         sectionId: section7.id,
         question: stmt,
         answerType: AnswerType.BOOLEAN,
         orderNo: idx + 1,
         isRequired: true,
      }));

      await prisma.profileQuestion.createMany({
         data: intentQuestions,
         skipDuplicates: true,
      });

      // ============================================================
      // 8. Personality Insights (Optional)
      // ============================================================
      const section8 = await prisma.profileSection.upsert({
         where: { key: "personality_insights" },
         update: { title: "Personality Insights", orderNo: 8 },
         create: {
            key: "personality_insights",
            title: "Personality Insights",
            orderNo: 8,
         },
      });

      await prisma.profileQuestion.createMany({
         data: [
            {
               sectionId: section8.id,
               question: "Are you Introvert / Ambivert / Extrovert?",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Introvert", "Ambivert", "Extrovert"],
               orderNo: 1,
               isRequired: false,
            },
            {
               sectionId: section8.id,
               question: "Decision style",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Logical", "Emotional", "Balanced"],
               orderNo: 2,
               isRequired: false,
            },
            {
               sectionId: section8.id,
               question: "Stress handling",
               answerType: AnswerType.SINGLE_CHOICE,
               options: ["Talk", "Internalize", "Distract"],
               orderNo: 3,
               isRequired: false,
            },
         ],
         skipDuplicates: true,
      });

      console.log("Seeding finished.");
   } catch (error) {
      console.error("Error during seeding:", error);
      process.exit(1);
   } finally {
      await prisma.$disconnect();
   }
}

main();
