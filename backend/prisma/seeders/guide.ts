import { PrismaClient } from "@prisma/client";

export async function seedGuide(prisma: PrismaClient) {
   console.log("Seeding guide questions...");

   const categories = [
      { id: 1, name: "About LPA", displayOrder: 1 },
      { id: 2, name: "Safety & Privacy", displayOrder: 2 },
      { id: 3, name: "Account & Trust", displayOrder: 3 },
      { id: 4, name: "Membership", displayOrder: 4 },
   ];

   for (const category of categories) {
      await prisma.guideCategory.upsert({
         where: { id: category.id },
         update: {
            name: category.name,
            displayOrder: category.displayOrder,
         },
         create: category,
      });
   }

   await prisma.$executeRaw`
      SELECT setval(
         pg_get_serial_sequence('"guide_categories"', 'id'),
         (SELECT COALESCE(MAX("id"), 1) FROM "guide_categories"),
         true
      )
   `;

   const guides = [
      {
         categoryId: 1,
         question: "What is Life Partner Again?",
         answer: "Life Partner Again (LPA) is a Canadian premium relationship platform created for mature individuals seeking genuine, long-term relationships and marriage. Whether you are divorced, widowed, separated, a single parent, or never married, LPA provides a safe and respectful environment to find your life partner.",
         bullets: [],
         displayOrder: 1,
      },
      {
         categoryId: 1,
         question: "Who can join Life Partner Again?",
         answer: "Anyone aged 18 or older who is genuinely looking for a serious relationship or marriage can join. We especially welcome divorced individuals, widows, widowers, single parents, and professionals seeking meaningful companionship.",
         bullets: [],
         displayOrder: 2,
      },
      {
         categoryId: 1,
         question: "Is Life Partner Again a dating app?",
         answer: "No. Life Partner Again is not designed for casual dating or hookups. Our focus is on helping people build serious, long-term relationships that can lead to marriage.",
         bullets: [],
         displayOrder: 3,
      },
      {
         categoryId: 2,
         question: "Is my information private?",
         answer: "Yes. Your personal information is protected using industry-standard security measures. We never sell your personal data to third parties.",
         bullets: [],
         displayOrder: 4,
      },
      {
         categoryId: 3,
         question: "How do I verify my account?",
         answer: "Verification helps build trust within our mature community. Verified users receive a verification badge, indicating that their identity has been verified by Life Partner Again.",
         bullets: [
            "Email verification (OTP)",
            "Selfie verification",
            "Profile review"
         ],
         displayOrder: 5,
      },
      {
         categoryId: 3,
         question: "What does the Verified Badge mean?",
         answer: "A verified badge indicates that the user’s identity has been verified by Life Partner Again, giving other members greater confidence when connecting.",
         bullets: [],
         displayOrder: 6,
      },
      {
         categoryId: 2,
         question: "Can I hide my profile?",
         answer: "Yes. You can control your profile visibility through your privacy settings and decide who can view your profile.",
         bullets: [],
         displayOrder: 7,
      },
      {
         categoryId: 2,
         question: "Can I block or report someone?",
         answer: "Absolutely. If someone behaves inappropriately, you can block and report them instantly. Our moderation team reviews all reports promptly.",
         bullets: [],
         displayOrder: 8,
      },
      {
         categoryId: 1,
         question: "Is Life Partner Again available worldwide?",
         answer: "Yes. Users from many countries can join, although some features may vary depending on location.",
         bullets: [],
         displayOrder: 9,
      },
      {
         categoryId: 4,
         question: "Is there a free membership?",
         answer: "Yes. Free members can create a profile, browse other members, receive messages, and express interest within the free plan limitations.",
         bullets: [],
         displayOrder: 10,
      },
      {
         categoryId: 4,
         question: "What additional benefits do Premium members receive?",
         answer: "Premium members enjoy additional features designed to make finding companionship simpler and safer:",
         bullets: [
            "Sending conversation requests",
            "Unlimited profile browsing",
            "Advanced search filters",
            "Seeing who viewed or liked their profile (where available)",
            "Priority customer support",
            "Additional premium features introduced in future updates"
         ],
         displayOrder: 11,
      },
      {
         categoryId: 4,
         question: "How do I cancel my subscription?",
         answer: "You can cancel your subscription anytime through your App Store, Google Play account, or your account settings. Your premium access continues until the end of your billing period.",
         bullets: [],
         displayOrder: 12,
      },
      {
         categoryId: 4,
         question: "Will my subscription renew automatically?",
         answer: "Yes. Unless cancelled before the renewal date, subscriptions renew automatically according to your selected plan.",
         bullets: [],
         displayOrder: 13,
      },
      {
         categoryId: 3,
         question: "Can I delete my account permanently?",
         answer: "Yes. You may permanently delete your account at any time from the Settings section. Once deleted, your profile and associated data will be removed according to our privacy policy.",
         bullets: [],
         displayOrder: 14,
      },
      {
         categoryId: 3,
         question: "Why was my account suspended?",
         answer: "Accounts may be suspended for violating our Community Guidelines, including:",
         bullets: [
            "Fake profiles",
            "Harassment",
            "Fraud",
            "Offensive content",
            "Misuse of the platform"
         ],
         displayOrder: 15,
      },
      {
         categoryId: 2,
         question: "How can I stay safe while meeting someone?",
         answer: "We prioritize our community's safety. Please remember these rules:",
         bullets: [
            "Communicate within the app first.",
            "Meet in a public place.",
            "Inform a trusted friend or family member.",
            "Never send money to someone you’ve only met online.",
            "Report suspicious behavior immediately."
         ],
         displayOrder: 16,
      },
      {
         categoryId: 3,
         question: "Can I change my profile information later?",
         answer: "Yes. You can update your photos, biography, interests, education, profession, and other profile details at any time.",
         bullets: [],
         displayOrder: 17,
      },
      {
         categoryId: 3,
         question: "What should I do if I forget my password?",
         answer: "Use the “Forgot Password” option on the login screen. We’ll send password reset instructions to your registered email address.",
         bullets: [],
         displayOrder: 18,
      },
      {
         categoryId: 2,
         question: "How do I contact customer support?",
         answer: "Visit the Help & Support section within the app or email our support team. We aim to respond as quickly as possible.",
         bullets: [],
         displayOrder: 19,
      },
      {
         categoryId: 1,
         question: "Why should I choose Life Partner Again?",
         answer: "Life Partner Again is built on trust, verification, privacy, and emotional maturity. Unlike casual dating platforms, our mission is to help sincere individuals find meaningful, lifelong relationships in a respectful and secure environment.",
         bullets: [],
         displayOrder: 20,
      },
   ];

   for (const item of guides) {
      await prisma.guide.upsert({
         where: { question: item.question },
         update: {
            answer: item.answer,
            categoryId: item.categoryId,
            bullets: item.bullets,
            displayOrder: item.displayOrder,
         },
         create: {
            question: item.question,
            answer: item.answer,
            categoryId: item.categoryId,
            bullets: item.bullets,
            displayOrder: item.displayOrder,
         },
      });
   }

   console.log(`Successfully seeded ${guides.length} guide questions.`);
}
