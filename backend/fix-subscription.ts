import prisma from './src/config/prisma';

async function main() {
  const freePlan = await prisma.subscriptionPlan.findUnique({
    where: { name: 'FREE' }
  });

  if (!freePlan) {
    console.error('FREE plan not found');
    return;
  }

  const startDate = new Date();
  const endDate = new Date(startDate.getTime() + freePlan.durationDays * 24 * 60 * 60 * 1000);

  const sub = await prisma.userSubscription.create({
    data: {
      userId: 1,
      planId: freePlan.id,
      status: 'ACTIVE',
      startDate: startDate,
      endDate: endDate,
      willRenew: true,
    }
  });

  console.log('Created subscription:', sub);
  
  // also create the user feature if it doesn't exist
  const existingFeatures = await prisma.userFeature.findUnique({ where: { userId: 1 } });
  if (!existingFeatures) {
    await prisma.userFeature.create({
      data: {
        userId: 1,
        isProfileBlurEnabled: false,
        maxInterests: 10,
        maxVideoCallMinutes: 0,
        maxAudioCallMinutes: 0,
        maxMessages: 5,
        interests: 0,
        videoCallMinutes: 0,
        audioCallMinutes: 0,
        messages: 0,
      }
    });
    console.log('Created user features for user 1');
  }
}

main().catch(console.error).finally(() => prisma.$disconnect());
