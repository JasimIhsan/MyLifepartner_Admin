import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  await prisma.user.updateMany({
    where: {
      id: { in: [1, 2] }
    },
    data: {
      isVerified: true
    }
  });

  await prisma.profile.updateMany({
    where: {
      userId: { in: [1, 2] }
    },
    data: {
      profileStatus: 'COMPLETED',
      profileCompletion: 100
    }
  });

  console.log('Successfully updated users 1 and 2 to be recommended to each other');
}

main()
  .catch(e => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
