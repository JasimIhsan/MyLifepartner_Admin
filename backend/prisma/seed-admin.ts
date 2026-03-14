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
   console.log("Start seeding admin user...");

   try {
      // Allow passing username and password as command line arguments
      // e.g., npm run seed:admin myadmin mypassword
      const username = process.argv[2] || "admin";
      const password = process.argv[3] || "asdfasdf"; // Default password if none provided

      const adminPasswordHash = await bcrypt.hash(password, 10);
      const admin = await prisma.admin.upsert({
         where: { username },
         update: {
            password: adminPasswordHash,
            role: Role.SUPER_ADMIN,
         },
         create: {
            username,
            password: adminPasswordHash,
            role: Role.SUPER_ADMIN,
         },
      });

      console.log(`Admin user '${admin.username}' seeded/updated successfully.`);
   } catch (error) {
      console.error("Error during admin seeding:", error);
      process.exit(1);
   } finally {
      await prisma.$disconnect();
   }
}

main();
