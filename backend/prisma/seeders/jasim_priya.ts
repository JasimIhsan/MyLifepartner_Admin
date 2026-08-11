import { ChildrenStatus, EmotionalReadiness, Gender, LookingFor, MaritalStatus, PrismaClient, ProfileStatus, RelationshipTimeline, Role, SelfieStatus, SubscriptionStatus, SwipeAction } from "@prisma/client";

interface ImageItem {
   imageUrl: string;
   isPrimary: boolean;
}

interface ProfileSeedData {
   email: string;
   password: string;
   name: string;
   gender: Gender;
   dob: Date;
   city: string;
   state: string | null;
   country: string;
   lat: number;
   lng: number;
   occupation: string;
   highestEducation: string;
   maritalStatus: MaritalStatus;
   motherTongue?: string;
   bio: string;
   languages: string[];
   childrenStatus: ChildrenStatus;
   emotionalReadiness: EmotionalReadiness;
   lookingFor: LookingFor;
   relationshipTimeline: RelationshipTimeline | null;
   selfieUrl: string;
   leftSelfieUrl: string;
   rightSelfieUrl: string;
   images: ImageItem[];
   keepExistingImages: boolean;
   preference: {
      ageFrom: number;
      ageTo: number;
      maritalStatus: MaritalStatus[];
      motherTongue?: string[];
   };
}

export async function seedJasimAndPriya(prisma: PrismaClient) {
   console.log("Seeding Jasim and Priya user profiles...");

   const profiles: ProfileSeedData[] = [
      // JASIM IHSAN
      {
         email: "jasimihsan1234@gmail.com",
         password: "$2b$10$5560JVISrbJuXY01kCnHlOpOGIGNdsrlYnJL0vsrc7P3WBmGHu0SK",
         name: "Jasim Ihsan",
         gender: Gender.MALE,
         dob: new Date("2001-06-01T00:00:00.000Z"),
         city: "Delhi",
         state: null,
         country: "India",
         lat: 11.1945413,
         lng: 76.3014534,
         occupation: "Software Engineer",
         highestEducation: "BACHELORS",
         maritalStatus: MaritalStatus.DIVORCED,
         motherTongue: "English",
         bio: "MERN developer building scalable apps, learning every day. Solving bugs. AI",
         languages: ["English"],
         childrenStatus: ChildrenStatus.LIVING_WITH_ME,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: null,
         selfieUrl: "1/selfie_front/126f529b-cc9a-436b-a4e4-547564eadf5c.jpg",
         leftSelfieUrl: "1/selfie_left/06b857c6-0476-4fe9-8542-b6d618f74156.jpg",
         rightSelfieUrl: "1/selfie_right/e8f26ee1-de60-41bb-890f-e5d8d7298caa.jpg",
         images: [],
         keepExistingImages: true,
         preference: {
            ageFrom: 20,
            ageTo: 30,
            maritalStatus: [MaritalStatus.DIVORCED],
            motherTongue: ["English"],
         },
      },
      // PRIYA WARRIOR
      {
         email: "priya@gmail.com",
         password: "$2b$10$0cSoeR.CYQ0G9i5CM3.S2O47sn5kZrRKzLrn1.Rh4Wbr/Sv/9Vo9S",
         name: "Priya Warrior",
         gender: Gender.FEMALE,
         dob: new Date("2001-07-18T00:00:00.000Z"),
         city: "Delhi",
         state: null,
         country: "India",
         lat: 11.1945384,
         lng: 76.3014543,
         occupation: "Actress",
         highestEducation: "BACHELORS",
         maritalStatus: MaritalStatus.DIVORCED,
         motherTongue: "English",
         bio: "I am an actress in Hollywood. Love to read. Polite, patient, character.",
         languages: ["English"],
         childrenStatus: ChildrenStatus.LIVING_WITH_ME,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: null,
         selfieUrl: "2/selfie_front/0aebf58a-57b7-4392-bff1-128c0bcc03de.jpg",
         leftSelfieUrl: "2/selfie_left/93307755-5c85-4bb9-b95a-094b7f19345f.jpg",
         rightSelfieUrl: "2/selfie_right/98488ee1-ba37-4915-b31d-65cb5c9afc91.jpg",
         images: [],
         keepExistingImages: true,
         preference: {
            ageFrom: 22,
            ageTo: 35,
            maritalStatus: [MaritalStatus.DIVORCED],
            motherTongue: ["English"],
         },
      },
   ];

   for (const p of profiles) {
      // 0) Find or create Job record
      let jobId: number | undefined;
      if (p.occupation) {
         let job = await prisma.job.findFirst({
            where: { name: { equals: p.occupation, mode: "insensitive" } },
         });
         if (!job) {
            job = await prisma.job.create({
               data: { name: p.occupation },
            });
         }
         jobId = job.id;
      }

      // 1) Upsert user
      const user = await prisma.user.upsert({
         where: { email: p.email },
         update: {
            password: p.password,
            isVerified: true,
            role: Role.USER,
            isBanned: false,
            isSuspended: false,
            isDeleted: false,
         },
         create: {
            email: p.email,
            password: p.password,
            isVerified: true,
            role: Role.USER,
         },
      });

      // 2) Upsert profile
      const profile = await prisma.profile.upsert({
         where: { userId: user.id },
         update: {
            name: p.name,
            gender: p.gender,
            dateOfBirth: p.dob,
            maritalStatus: p.maritalStatus,
            motherTongue: p.motherTongue ?? p.languages[0] ?? null,
            city: p.city,
            state: p.state,
            country: p.country,
            lastLocationLat: p.lat,
            lastLocationLng: p.lng,
            highestEducation: p.highestEducation,
            jobId: jobId ?? null,
            bio: p.bio,
            languages: p.languages,
            childrenStatus: p.childrenStatus,
            emotionalReadiness: p.emotionalReadiness,
            lookingFor: p.lookingFor,
            relationshipTimeline: p.relationshipTimeline,
            profileCompletion: 100,
            profileStatus: ProfileStatus.COMPLETED,
            hasCompletedBasicDetails: true,
            hasCompletedPartnerPreference: true,
            hasCompletedImageUpload: true,
            selfieUrl: p.selfieUrl,
            leftSelfieUrl: p.leftSelfieUrl,
            rightSelfieUrl: p.rightSelfieUrl,
            selfieStatus: SelfieStatus.APPROVED,
         },
         create: {
            userId: user.id,
            name: p.name,
            gender: p.gender,
            dateOfBirth: p.dob,
            maritalStatus: p.maritalStatus,
            motherTongue: p.motherTongue ?? p.languages[0] ?? null,
            city: p.city,
            state: p.state,
            country: p.country,
            lastLocationLat: p.lat,
            lastLocationLng: p.lng,
            highestEducation: p.highestEducation,
            jobId: jobId ?? null,
            bio: p.bio,
            languages: p.languages,
            childrenStatus: p.childrenStatus,
            emotionalReadiness: p.emotionalReadiness,
            lookingFor: p.lookingFor,
            relationshipTimeline: p.relationshipTimeline,
            profileCompletion: 100,
            profileStatus: ProfileStatus.COMPLETED,
            hasCompletedBasicDetails: true,
            hasCompletedPartnerPreference: true,
            hasCompletedImageUpload: true,
            selfieUrl: p.selfieUrl,
            leftSelfieUrl: p.leftSelfieUrl,
            rightSelfieUrl: p.rightSelfieUrl,
            selfieStatus: SelfieStatus.APPROVED,
         },
      });

      // 3) Upsert user images if provided
      if (p.images.length > 0) {
         const existingImagesCount = await prisma.userImage.count({
            where: { profileId: profile.id },
         });

         if (existingImagesCount === 0 || !p.keepExistingImages) {
            await prisma.userImage.deleteMany({
               where: { profileId: profile.id },
            });

            for (const img of p.images) {
               await prisma.userImage.create({
                  data: {
                     profileId: profile.id,
                     imageUrl: img.imageUrl,
                     isPrimary: img.isPrimary,
                  },
               });
            }
         }
      }

      // 4) Upsert partner preference
      await prisma.partnerPreference.upsert({
         where: { userId: user.id },
         update: {
            ageFrom: p.preference.ageFrom,
            ageTo: p.preference.ageTo,
            maritalStatus: p.preference.maritalStatus,
            motherTongue: p.preference.motherTongue ?? p.languages,
         },
         create: {
            userId: user.id,
            ageFrom: p.preference.ageFrom,
            ageTo: p.preference.ageTo,
            maritalStatus: p.preference.maritalStatus,
            motherTongue: p.preference.motherTongue ?? p.languages,
         },
      });

      console.log(`Seeded profile: ${p.name}`);
   }

   // 5) Make Jasim and Priya mutual connections (mutual right swipes)
   const jasimUser = await prisma.user.findUnique({ where: { email: "jasimihsan1234@gmail.com" }, include: { profile: true } });
   const priyaUser = await prisma.user.findUnique({ where: { email: "priya@gmail.com" }, include: { profile: true } });

   if (jasimUser?.profile && priyaUser?.profile) {
      const existingJTP = await prisma.profileSwipe.findFirst({
         where: { userId: jasimUser.id, targetProfileId: priyaUser.profile.id },
      });
      if (!existingJTP) {
         await prisma.profileSwipe.create({
            data: { userId: jasimUser.id, targetProfileId: priyaUser.profile.id, action: SwipeAction.RIGHT },
         });
      }

      const existingPTJ = await prisma.profileSwipe.findFirst({
         where: { userId: priyaUser.id, targetProfileId: jasimUser.profile.id },
      });
      if (!existingPTJ) {
         await prisma.profileSwipe.create({
            data: { userId: priyaUser.id, targetProfileId: jasimUser.profile.id, action: SwipeAction.RIGHT },
         });
      }
      console.log("Jasim and Priya are now mutual connections.");
   }

   // 6) Create Premium Subscription and User Features for both
   let premiumPlan = await prisma.subscriptionPlan.findUnique({
      where: { name: "PREMIUM" },
   });

   if (!premiumPlan) {
      premiumPlan = await prisma.subscriptionPlan.create({
         data: {
            name: "PREMIUM",
            price: 999,
            durationDays: 30,
            isActive: true,
            isMostPopular: true,
            description: "Unlock all premium features, unlimited interest requests, video calls, and priority matching.",
            storeProductId: "premium_monthly",
         },
      });
   }

   const oneMonthFromNow = new Date();
   oneMonthFromNow.setMonth(oneMonthFromNow.getMonth() + 1);

   for (const u of [jasimUser, priyaUser]) {
      if (u) {
         // Delete existing active premium subscriptions to avoid duplicates on re-seed
         await prisma.userSubscription.deleteMany({
            where: { userId: u.id, planId: premiumPlan.id, status: SubscriptionStatus.ACTIVE },
         });

         await prisma.userSubscription.create({
            data: {
               userId: u.id,
               planId: premiumPlan.id,
               startDate: new Date(),
               endDate: oneMonthFromNow,
               status: SubscriptionStatus.ACTIVE,
            },
         });

         await prisma.userFeature.upsert({
            where: { userId: u.id },
            update: {
               isProfileBlurEnabled: true,
               maxInterests: 100,
               maxVideoCallMinutes: 100,
               maxAudioCallMinutes: 100,
               maxMessages: 1000,
               interests: 100,
               videoCallMinutes: 100,
               audioCallMinutes: 100,
               messages: 1000,
            },
            create: {
               userId: u.id,
               isProfileBlurEnabled: true,
               maxInterests: 100,
               maxVideoCallMinutes: 100,
               maxAudioCallMinutes: 100,
               maxMessages: 1000,
               interests: 100,
               videoCallMinutes: 100,
               audioCallMinutes: 100,
               messages: 1000,
            },
         });
      }
   }
   console.log("Premium subscriptions and features added for Jasim and Priya.");

   console.log("Jasim and Priya seeding completed successfully.");
}
