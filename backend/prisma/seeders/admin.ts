import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient, Role } from "@prisma/client";
import bcrypt from "bcrypt";
import * as dotenv from "dotenv";
import { Pool } from "pg";

export async function seedAdmins(prisma: PrismaClient) {
   console.log("Seeding admins...");

   const username = process.argv[2] || process.env.ADMIN_USERNAME || "admin";
   const password = process.argv[3] || process.env.ADMIN_PASSWORD || "asdfasdf";

   const adminPasswordHash = await bcrypt.hash(password, 10);
   
   const admin = await prisma.admins.upsert({
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
}

// Standalone execution support
if (require.main === module) {
   dotenv.config();
   const connectionString = `${process.env.DATABASE_URL}`;
   const pool = new Pool({ connectionString });
   const adapter = new PrismaPg(pool);
   const prisma = new PrismaClient({ adapter });

   seedAdmins(prisma)
      .catch((e) => {
         console.error(e);
         process.exit(1);
      })
      .finally(async () => {
         await prisma.$disconnect();
      });
}
