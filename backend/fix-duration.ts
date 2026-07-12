import prisma from './src/config/prisma';
async function main() {
  await prisma.subscriptionPlan.update({
    where: { name: 'FREE' },
    data: { durationDays: 36500 }
  });
  console.log('Fixed FREE plan durationDays to 36500');
}
main().finally(() => prisma.$disconnect());
