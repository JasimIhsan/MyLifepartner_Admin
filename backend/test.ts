import prisma from './src/config/prisma';
async function main() {
  const freePlan = await prisma.subscriptionPlan.findUnique({
    where: { name: 'FREE' }
  });
  console.log('freePlan:', freePlan);
}
main().finally(() => prisma.$disconnect());
