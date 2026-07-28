import { ChildrenStatus, EmotionalReadiness, Gender, LookingFor, MaritalStatus, PrismaClient, ProfileStatus, RelationshipTimeline, Role, SelfieStatus, SwipeAction } from "@prisma/client";
import bcrypt from "bcrypt";

export async function seedUsers(prisma: PrismaClient) {
   console.log("Seeding dummy user profiles...");

   const defaultPasswordHash = await bcrypt.hash("Jasim9656@", 10);
   const commonSelfieUrl = "1/selfie_front/70278098-2a48-45e9-8475-b65093279d35.jpg";

   const dummyProfiles = [
      // FEMALE PROFILES
      {
         email: "aisha@gmail.com",
         password: defaultPasswordHash,
         name: "Aisha Rahman",
         gender: Gender.FEMALE,
         dob: new Date("1999-01-01"),
         heightCm: 163,
         city: "Kochi",
         state: "Kerala",
         country: "India",
         lat: 9.9312,
         lng: 76.2673,
         occupation: "Software Engineer",
         highestEducation: "B.Tech Computer Science",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "I work as a software engineer and enjoy building meaningful products. I value honesty, deen, family, and a peaceful life.",
         languages: ["Malayalam", "English", "Hindi"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: commonSelfieUrl,
         leftSelfieUrl: commonSelfieUrl,
         rightSelfieUrl: commonSelfieUrl,
         images: [{ imageUrl: "https://images.unsplash.com/photo-1609505848912-b7c3b8b4beda?q=80&w=765&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D", isPrimary: true }],
         preference: {
            ageFrom: 27,
            ageTo: 33,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: ["B.Tech", "M.Tech", "MBA", "MBBS"],
            occupation: ["Software Engineer", "Doctor", "Business", "Engineer"],
         },
      },
      {
         email: "sana@gmail.com",
         password: defaultPasswordHash,
         name: "Sana Malik",
         gender: Gender.FEMALE,
         dob: new Date("1999-01-01"),
         heightCm: 158,
         city: "Bengaluru",
         state: "Karnataka",
         country: "India",
         lat: 12.9716,
         lng: 77.5946,
         occupation: "Doctor",
         highestEducation: "MBBS",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "Doctor by profession, calm by nature. Looking for a kind, mature life partner who values both family and personal growth.",
         languages: ["Urdu", "English", "Hindi"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: commonSelfieUrl,
         leftSelfieUrl: commonSelfieUrl,
         rightSelfieUrl: commonSelfieUrl,
         images: [{ imageUrl: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8N3x8Z2lybHxlbnwwfHwwfHx8MA%3D%3D", isPrimary: true }],
         preference: {
            ageFrom: 27,
            ageTo: 35,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: ["MBBS", "MD", "B.Tech", "MBA"],
            occupation: ["Doctor", "Software Engineer", "Business", "Civil Engineer"],
         },
      },
      {
         email: "fatima@gmail.com",
         password: defaultPasswordHash,
         name: "Fatima Zahra",
         gender: Gender.FEMALE,
         dob: new Date("1995-01-01"),
         heightCm: 165,
         city: "Hyderabad",
         state: "Telangana",
         country: "India",
         lat: 17.385,
         lng: 78.4867,
         occupation: "Teacher",
         highestEducation: "M.A English",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "I love teaching and spending time with family. Hoping to build a respectful, emotionally healthy marriage with shared values.",
         languages: ["Urdu", "English", "Telugu"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: commonSelfieUrl,
         leftSelfieUrl: commonSelfieUrl,
         rightSelfieUrl: commonSelfieUrl,
         images: [{ imageUrl: "https://images.unsplash.com/photo-1589571894960-20bbe2828d0a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NDN8fGdpcmx8ZW58MHx8MHx8fDA%3D", isPrimary: true }],
         preference: {
            ageFrom: 29,
            ageTo: 36,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: ["M.A", "MBA", "B.Tech", "M.Tech"],
            occupation: ["Teacher", "Software Engineer", "Manager", "Business"],
         },
      },
      // PRIYANKA CHOPRA (from user JSON)
      {
         email: "priyankachopra001@gmail.com",
         password: "$2b$10$S/9T6i5Wns8ayMt05lt5tOnQAJBn6x9Sf.V67az9c5R5qxOHMsf1C",
         name: "Priyank Chopra",
         gender: Gender.FEMALE,
         dob: new Date("2001-09-06T00:00:00.000Z"),
         heightCm: 170,
         city: "Delhi",
         state: null,
         country: "India",
         lat: 10.7543589,
         lng: 76.6466039,
         occupation: "Actress",
         highestEducation: "HIGH_SCHOOL",
         maritalStatus: MaritalStatus.SEPARATED,
         bio: "Bollywood actress looking for the one.",
         languages: ["English"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: "13/selfie_front/2ef8bfa4-2451-4b28-8492-0503c15964b1.jpg",
         leftSelfieUrl: "13/selfie_left/82488d63-7361-4144-a5fc-a68ebd147e6d.jpg",
         rightSelfieUrl: "13/selfie_right/3bd6a068-a038-4b62-802b-da8547263449.jpg",
         images: [
            { imageUrl: "13/profile/e5184eca-dbcd-403b-bf0d-0e184b489a4f.jpg", isPrimary: true },
            { imageUrl: "13/profile/b98301a5-39e2-4b7a-bd46-2042c07377de.jpg", isPrimary: false },
            { imageUrl: "13/profile/6b60e6b8-0ca7-4788-aa4f-e46792accf26.jpg", isPrimary: false },
            { imageUrl: "13/profile/84df1946-8475-49d1-99d4-a5118ed21b56.jpg", isPrimary: false },
         ],
         preference: {
            ageFrom: 22,
            ageTo: 35,
            maritalStatus: [MaritalStatus.SEPARATED, MaritalStatus.DIVORCED],
            highestEducation: [],
            occupation: [],
         },
      },
      // BINU (from user JSON)
      {
         email: "binu@gmail.com",
         password: "$2b$10$sklDcVw3oH6m0YOBXM18b.Cq0XPdqeGUFNnctuP6CBhVWHd70tITu",
         name: "Binu",
         gender: Gender.MALE,
         dob: new Date("2001-07-01T00:00:00.000Z"),
         heightCm: 171,
         city: "Delhi",
         state: null,
         country: "India",
         lat: 10.7543589,
         lng: 76.6466039,
         occupation: "Uf",
         highestEducation: "HIGH_SCHOOL",
         maritalStatus: MaritalStatus.SEPARATED,
         bio: "I am a simple man looking for a partner to share life with.",
         languages: ["English"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: "12/selfie_front/e6c0cddd-dfd3-4363-9793-019724708144.jpg",
         leftSelfieUrl: "12/selfie_left/0a7405cd-ad64-4b24-a066-1b3dcd861754.jpg",
         rightSelfieUrl: "12/selfie_right/8b7dcdc9-460d-41c4-b01b-8f8e708b6e8f.jpg",
         images: [
            { imageUrl: "12/profile/79d0d248-088a-4508-ba3f-a9bccf536568.jpg", isPrimary: true },
            { imageUrl: "12/profile/f02158b9-6977-42fd-8445-45f0aef78423.jpg", isPrimary: false },
            { imageUrl: "12/profile/de1971ca-a8ee-4e45-be99-6409fe61bf47.jpg", isPrimary: false },
            { imageUrl: "12/profile/305f8b01-3e85-4d18-9114-5d37990e90a5.jpg", isPrimary: false },
         ],
         preference: {
            ageFrom: 22,
            ageTo: 35,
            maritalStatus: [MaritalStatus.SEPARATED, MaritalStatus.DIVORCED],
            highestEducation: [],
            occupation: [],
         },
      },
      // MALE PROFILES
      {
         email: "rahul@gmail.com",
         password: defaultPasswordHash,
         name: "Rahul Sharma",
         gender: Gender.MALE,
         dob: new Date("1993-05-10"),
         heightCm: 180,
         city: "Mumbai",
         state: "Maharashtra",
         country: "India",
         lat: 19.076,
         lng: 72.8777,
         occupation: "Entrepreneur",
         highestEducation: "MBA",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "Passionate about my startup, love exploring new cities, and enjoy a balanced lifestyle.",
         languages: ["Hindi", "English", "Marathi"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: commonSelfieUrl,
         leftSelfieUrl: commonSelfieUrl,
         rightSelfieUrl: commonSelfieUrl,
         images: [{ imageUrl: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTB8fG1hbnxlbnwwfHwwfHx8MA%3D%3D", isPrimary: true }],
         preference: {
            ageFrom: 25,
            ageTo: 32,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: ["B.Tech", "MBA", "M.A"],
            occupation: ["Business", "Software Engineer", "Teacher"],
         },
      },
      {
         email: "zayed@gmail.com",
         password: defaultPasswordHash,
         name: "Zayed Ali",
         gender: Gender.MALE,
         dob: new Date("1996-08-15"),
         heightCm: 175,
         city: "Bengaluru",
         state: "Karnataka",
         country: "India",
         lat: 12.9716,
         lng: 77.5946,
         occupation: "Data Scientist",
         highestEducation: "M.Tech",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "Calm, logical, and family-oriented. Enjoy reading books and weekend hikes.",
         languages: ["Urdu", "English", "Kannada"],
         childrenStatus: ChildrenStatus.NO_CHILDREN,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.MARRIAGE,
         relationshipTimeline: RelationshipTimeline.ZERO_TO_SIX_MONTHS,
         selfieUrl: commonSelfieUrl,
         leftSelfieUrl: commonSelfieUrl,
         rightSelfieUrl: commonSelfieUrl,
         images: [{ imageUrl: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTl8fG1hbnxlbnwwfHwwfHx8MA%3D%3D", isPrimary: true }],
         preference: {
            ageFrom: 24,
            ageTo: 30,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: ["B.Tech", "M.Tech", "MBA", "MBBS"],
            occupation: ["Software Engineer", "Doctor", "Teacher", "Business"],
         },
      },
      // JASIM IHSAN (from user JSON)
      {
         email: "jasimihsan1234@gmail.com",
         password: "$2b$10$5560JVISrbJuXY01kCnHlOpOGIGNdsrlYnJL0vsrc7P3WBmGHu0SK",
         name: "Jasim Ihsan",
         gender: Gender.MALE,
         dob: new Date("2001-06-01T00:00:00.000Z"),
         heightCm: 183,
         city: "Delhi",
         state: null,
         country: "India",
         lat: 11.1945413,
         lng: 76.3014534,
         occupation: "Software Engineer",
         highestEducation: "BACHELORS",
         maritalStatus: MaritalStatus.DIVORCED,
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
            highestEducation: [],
            occupation: [],
         },
      },
      // PRIYA WARRIOR (from user JSON)
      {
         email: "priya@gmail.com",
         password: "$2b$10$0cSoeR.CYQ0G9i5CM3.S2O47sn5kZrRKzLrn1.Rh4Wbr/Sv/9Vo9S",
         name: "Priya Warrior",
         gender: Gender.FEMALE,
         dob: new Date("2001-07-18T00:00:00.000Z"),
         heightCm: 173,
         city: "Delhi",
         state: null,
         country: "India",
         lat: 11.1945384,
         lng: 76.3014543,
         occupation: "Actress",
         highestEducation: "BACHELORS",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "I am an actress in Hollywood. Love to read. Polite, patient, charector ",
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
            highestEducation: [],
            occupation: [],
         },
      },
      // DEV HUNTER (from user JSON)
      {
         email: "jasimihsandev@gmail.com",
         password: "$2b$10$Yj3xPPDxq1tKpSHIsz6tROEgQh3AFk6zQYfDS1tILLXD/ldvUSmn2",
         name: "Dev Hunter",
         gender: Gender.MALE,
         dob: new Date("2001-07-18T00:00:00.000Z"),
         heightCm: 172,
         city: "Haryana",
         state: null,
         country: "India",
         lat: 11.1945399,
         lng: 76.3014512,
         occupation: "Software Engineer",
         highestEducation: "BACHELORS",
         maritalStatus: MaritalStatus.DIVORCED,
         bio: "Software developer",
         languages: ["English"],
         childrenStatus: ChildrenStatus.NOT_LIVING_WITH_ME,
         emotionalReadiness: EmotionalReadiness.YES,
         lookingFor: LookingFor.LONG_TERM_RELATIONSHIP,
         relationshipTimeline: null,
         selfieUrl: "3/selfie_front/c018620c-211c-4d15-a229-c4cb9178b36f.jpg",
         leftSelfieUrl: "3/selfie_left/d29791cf-622c-4e2d-9e76-f91d8dd63c84.jpg",
         rightSelfieUrl: "3/selfie_right/47b0dcba-05db-43f8-b309-d89cd9703643.jpg",
         images: [],
         keepExistingImages: true,
         preference: {
            ageFrom: 20,
            ageTo: 30,
            maritalStatus: [MaritalStatus.DIVORCED],
            highestEducation: [],
            occupation: [],
         },
      },
   ];

   for (const p of dummyProfiles) {
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

      // 1) Create or update user
      const user = await prisma.user.upsert({
         where: { email: p.email },
         update: {
            password: p.password,
            isVerified: true,
            role: Role.USER,
            isBlocked: false,
            isDeleted: false,
         },
         create: {
            email: p.email,
            password: p.password,
            isVerified: true,
            role: Role.USER,
         },
      });

      // 2) Create or update profile
      const profile = await prisma.profile.upsert({
         where: { userId: user.id },
         update: {
            name: p.name,
            gender: p.gender,
            dateOfBirth: p.dob,
            maritalStatus: p.maritalStatus,
            motherTongue: p.languages?.[0] ?? null,
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
            motherTongue: p.languages?.[0] ?? null,
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

      // 3) Replace old profile images
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

      // 4) Create or update partner preference
      await prisma.partnerPreference.upsert({
         where: { userId: user.id },
         update: {
            ageFrom: p.preference.ageFrom,
            ageTo: p.preference.ageTo,
            maritalStatus: p.preference.maritalStatus,
            motherTongue: p.languages ?? [],
         },
         create: {
            userId: user.id,
            ageFrom: p.preference.ageFrom,
            ageTo: p.preference.ageTo,
            maritalStatus: p.preference.maritalStatus,
            motherTongue: p.languages ?? [],
         },
      });

      console.log(`User seeded: ${p.name}`);
   }

   // 5) Make Priyanka and Binu mutual connections
   const priyanka = await prisma.user.findUnique({ where: { email: "priyankachopra001@gmail.com" }, include: { profile: true } });
   const binu = await prisma.user.findUnique({ where: { email: "binu@gmail.com" }, include: { profile: true } });

   if (priyanka?.profile && binu?.profile) {
      // Priyanka swipes right on Binu
      const existingPTB = await prisma.profileSwipe.findFirst({
         where: { userId: priyanka.id, targetProfileId: binu.profile.id },
      });
      if (!existingPTB) {
         await prisma.profileSwipe.create({
            data: { userId: priyanka.id, targetProfileId: binu.profile.id, action: SwipeAction.RIGHT },
         });
      }

      // Binu swipes right on Priyanka
      const existingBTP = await prisma.profileSwipe.findFirst({
         where: { userId: binu.id, targetProfileId: priyanka.profile.id },
      });
      if (!existingBTP) {
         await prisma.profileSwipe.create({
            data: { userId: binu.id, targetProfileId: priyanka.profile.id, action: SwipeAction.RIGHT },
         });
      }
      console.log("Priyanka and Binu are now mutual connections.");
   }

   // 6) Make Jasim and Priya mutual connections
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

   console.log("Dummy user profiles seeded successfully!");
}
