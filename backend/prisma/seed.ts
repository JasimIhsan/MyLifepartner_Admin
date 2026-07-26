import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import * as dotenv from "dotenv";
import { Pool } from "pg";
import { seedAdmins } from "./seeders/admin";
import { seedGuide } from "./seeders/guide";
import { seedJasimAndPriya } from "./seeders/jasim_priya";
import { seedJobs } from "./seeders/jobs";
import { seedSubscriptionPlans } from "./seeders/plan";

dotenv.config();

const connectionString = `${process.env.DATABASE_URL}`;

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
   console.log("Starting database seeding process...");

   try {
      // Execute each seeder in sequence
      // await seedAdmins(prisma);
      // await seedJobs(prisma);
      // await seedSubscriptionPlans(prisma);
      await seedJasimAndPriya(prisma);
      // await seedProfileData(prisma);
      // await seedUsers(prisma);
      // await seedMutualConnections(prisma);
      // await seedGuide(prisma);

      console.log("Database seeding completed successfully.");
   } catch (error) {
      console.error("Error during seeding process:", error);
      process.exit(1);
   } finally {
      await prisma.$disconnect();
   }
}

main();
