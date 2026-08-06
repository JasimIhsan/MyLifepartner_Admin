import dotenv from 'dotenv';
dotenv.config();

import prisma from '../config/prisma';
import { runBroadcastNotificationJob } from '../jobs/broadcastNotification.job';

async function main() {
  try {
    const result = await runBroadcastNotificationJob(
      'New Profiles Available!',
      'Hey, Checkout the application to find new profiles.'
    );
    console.log(result.message);
  } catch (error) {
    console.error('Manual broadcast failed:', error);
  } finally {
    await prisma.$disconnect();
    process.exit(0);
  }
}

main();

