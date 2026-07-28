import { PrismaClient } from '@prisma/client';
import logger from '../utils/logger';

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
  logger.info('Successfully updated users 1 and 2 to be recommended to each other');
}

main()
  .catch(e => {
    logger.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
