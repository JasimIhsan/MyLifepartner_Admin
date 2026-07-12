import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import * as dotenv from "dotenv";
import { Pool } from "pg";
import { seedGuide } from "./seeders/guide";

dotenv.config();

const connectionString = `${process.env.DATABASE_URL}`;

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
   console.log("Starting guide seeding process...");

   try {
      await seedGuide(prisma);

      console.log("Guide seeding completed successfully.");
   } catch (error) {
      console.error("Error during guide seeding process:", error);
      process.exit(1);
   } finally {
      await prisma.$disconnect();
   }
}

main();
