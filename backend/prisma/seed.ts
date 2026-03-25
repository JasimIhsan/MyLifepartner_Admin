import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient, Role } from "@prisma/client";
import bcrypt from "bcrypt";
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
      await prisma.userAnswer.deleteMany({});
      await prisma.profileQuestion.deleteMany({});
      await prisma.profileSection.deleteMany({});

      // Seed Admin
      const adminPasswordHash = await bcrypt.hash("asdfasdf", 10);
      const mainAdmin = await prisma.admins.upsert({
         where: { username: "admin" },
         update: {},
         create: {
            username: "admin",
            password: adminPasswordHash,
            role: Role.SUPER_ADMIN,
         },
      });

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
               answerType: "SINGLE_CHOICE",
               options: ["Ready to settle down", "Looking for a life partner", "Tired of casual dating", "Family pressure / Recommendation", "Recently single and want something serious", "Want companionship and commitment"],
               orderNo: 1,
               isRequired: true,
               isActive: true,
            },
            // Add more profile questions here
         ],
      });

      // Add more profile sections and profile questions here

      console.log("Seeding successful!");
   } catch (error) {
      console.error("Error during seeding:", error);
   } finally {
      await prisma.$disconnect();
   }
}

main();
