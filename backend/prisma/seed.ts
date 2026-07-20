import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";
import * as dotenv from "dotenv";
import { Pool } from "pg";
import { seedAdmins } from "./seeders/admin";
import { seedSubscriptionPlans } from "./seeders/plan";
import { seedProfileData } from "./seeders/answers";
import { seedUsers } from "./seeders/user";
import { seedMutualConnections } from "./seeders/mutual_connections";
import { seedGuide } from "./seeders/guide";
import { seedJobs } from "./seeders/jobs";

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
      // await seedSubscriptionPlans(prisma);
      // await seedProfileData(prisma);
      // await seedUsers(prisma);
      // await seedMutualConnections(prisma);
      await seedJobs(prisma);
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
