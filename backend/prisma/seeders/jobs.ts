import { PrismaClient } from "@prisma/client";

export async function seedJobs(prisma: PrismaClient) {
   console.log("Seeding jobs...");

   const defaultJobs = [
      "Software Developer",
      "Doctor",
      "Teacher",
      "Marketing Manager",
      "Designer",
      "Nurse",
      "Engineer",
      "Accountant",
      "Sales Representative",
      "Chef",
      "Project Manager",
      "Data Analyst",
      "Lawyer",
      "Graphic Designer",
      "Writer",
      "Pharmacist",
      "Business Analyst",
      "Human Resources",
      "Dentist",
      "Electrician",
      "Mechanic"
   ];

   for (const jobName of defaultJobs) {
      const existing = await prisma.job.findFirst({
         where: { name: { equals: jobName, mode: "insensitive" } },
      });

      if (!existing) {
         await prisma.job.create({
            data: { name: jobName },
         });
      }
   }

   console.log("Jobs seeded successfully.");
}
