import { ChildrenStatus, EmotionalReadiness, Gender, LookingFor, MaritalStatus, PrismaClient, ProfileStatus, RelationshipTimeline, Role, SelfieStatus, SwipeAction } from "@prisma/client";
import bcrypt from "bcrypt";

export async function seedMutualConnections(prisma: PrismaClient) {
   console.log("Seeding mutual connections for dummyhunterr@gmail.com...");

   const dummyEmail = "dummyhunterr@gmail.com";

   // 1) Find or Create dummy user
   let dummyUser = await prisma.user.findUnique({
      where: { email: dummyEmail },
      include: { profile: true },
   });

   if (!dummyUser) {
      console.log(`User ${dummyEmail} not found, creating dummy user...`);
      const passwordHash = await bcrypt.hash("password123", 10);
      const dob = new Date();
      dob.setFullYear(dob.getFullYear() - 28);

      dummyUser = await prisma.user.create({
         data: {
            email: dummyEmail,
            password: passwordHash,
            role: Role.USER,
            isVerified: true,
            profile: {
               create: {
                  name: "Dummy Hunter",
                  profileCompletion: 100,
                  profileStatus: ProfileStatus.COMPLETED,
                  gender: Gender.MALE,
                  dateOfBirth: dob,
                  maritalStatus: MaritalStatus.DIVORCED,
                  city: "Bengaluru",
                  state: "Karnataka",
                  country: "India",
                  lookingFor: LookingFor.MARRIAGE,
                  emotionalReadiness: EmotionalReadiness.YES,
                  childrenStatus: ChildrenStatus.NO_CHILDREN,
                  relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
                  hasCompletedBasicDetails: true,
                  hasCompletedPartnerPreference: true,
                  hasCompletedImageUpload: true,
                  selfieStatus: SelfieStatus.APPROVED,
               },
            },
         },
         include: { profile: true },
      });
   }

   if (!dummyUser.profile) {
      console.log("Error: Profile missing for dummy user");
      return;
   }

   const targetEmails = ["aisha@gmail.com", "sana@gmail.com", "fatima@gmail.com", "nadia@gmail.com", "mariam@gmail.com"];

   let connectionsCreated = 0;

   // 2) Create Mutual Right Swipes
   for (const email of targetEmails) {
      const targetUser = await prisma.user.findUnique({
         where: { email },
         include: { profile: true },
      });

      if (targetUser && targetUser.profile) {
         // Dummy user swipes right on target
         const existingDummyToTarget = await prisma.profileSwipe.findFirst({
            where: { userId: dummyUser.id, targetProfileId: targetUser.profile.id },
         });

         if (!existingDummyToTarget) {
            await prisma.profileSwipe.create({
               data: {
                  userId: dummyUser.id,
                  targetProfileId: targetUser.profile.id,
                  action: SwipeAction.RIGHT,
               },
            });
         }

         // Target swipes right on dummy user
         const existingTargetToDummy = await prisma.profileSwipe.findFirst({
            where: { userId: targetUser.id, targetProfileId: dummyUser.profile.id },
         });

         if (!existingTargetToDummy) {
            await prisma.profileSwipe.create({
               data: {
                  userId: targetUser.id,
                  targetProfileId: dummyUser.profile.id,
                  action: SwipeAction.RIGHT,
               },
            });
         }

         connectionsCreated++;
      } else {
         console.log(`Target user ${email} not found or missing profile.`);
      }
   }

   console.log(`Successfully ensured ${connectionsCreated} mutual connections for ${dummyEmail} in database.`);
}
