import { UserService } from "@/services/user.service";
import { IUserRepository, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { S3Service } from "@/services/s3.service";

jest.mock("@/config/prisma", () => {
   const mockPrismaClient = {
      $transaction: jest.fn(),
      archivedUserData: {
         count: jest.fn(),
         findMany: jest.fn(),
      },
      user: {
         count: jest.fn(),
         findMany: jest.fn(),
         findUnique: jest.fn(),
         update: jest.fn(),
      },
   };

   return {
      __esModule: true,
      default: mockPrismaClient,
      prisma: mockPrismaClient,
   };
});

const makeUser = (overrides: Partial<UserWithProfile> = {}): UserWithProfile =>
   ({
      id: 42,
      mobileNumber: null,
      email: "member@example.com",
      password: null,
      isVerified: false,
      isBanned: false,
      isSuspended: false,
      isFoundingMember: false,
      foundingMemberSince: null,
      bannedAt: null,
      suspendedAt: null,
      isDeleted: false,
      isDeleteRequested: false,
      deleteRequestedAt: null,
      deleteRequestStatus: null,
      role: "USER",
      createdAt: new Date("2026-01-01T00:00:00.000Z"),
      updatedAt: new Date("2026-01-01T00:00:00.000Z"),
      profile: null,
      partnerPreference: null,
      userFeature: null,
      privacySettings: null,
      ...overrides,
   }) as UserWithProfile;

const mockUserRepository = {
   findById: jest.fn(),
   updateFoundingMemberStatus: jest.fn(),
};

const makeService = () =>
   new UserService(
      mockUserRepository as unknown as IUserRepository,
      {} as S3Service,
      {} as IEmailService,
      {} as ICacheService
   );

describe("UserService founding-member status", () => {
   beforeEach(() => {
      jest.clearAllMocks();
   });

   it("prevents granting founding-member status to an unverified user", async () => {
      mockUserRepository.findById.mockResolvedValue(makeUser({ isVerified: false, isFoundingMember: false }));

      await expect(makeService().toggleFoundingMemberStatus(42)).rejects.toMatchObject({
         statusCode: 403,
         message: "Only verified users can be granted founding-member status",
      });

      expect(mockUserRepository.updateFoundingMemberStatus).not.toHaveBeenCalled();
   });

   it("grants founding-member status to a verified user", async () => {
      const foundingMemberSince = new Date("2026-02-01T00:00:00.000Z");
      mockUserRepository.findById.mockResolvedValue(makeUser({ isVerified: true, isFoundingMember: false }));
      mockUserRepository.updateFoundingMemberStatus.mockResolvedValue(
         makeUser({ isVerified: true, isFoundingMember: true, foundingMemberSince })
      );

      const result = await makeService().toggleFoundingMemberStatus(42);

      expect(mockUserRepository.updateFoundingMemberStatus).toHaveBeenCalledWith(42, true, expect.any(Date));
      expect(result.previousIsFoundingMember).toBe(false);
      expect(result.user.isFoundingMember).toBe(true);
      expect(result.user.foundingMemberSince).toBe(foundingMemberSince);
   });

   it("allows revoking founding-member status even if the user is no longer verified", async () => {
      const previousFoundingMemberSince = new Date("2026-02-01T00:00:00.000Z");
      mockUserRepository.findById.mockResolvedValue(
         makeUser({
            isVerified: false,
            isFoundingMember: true,
            foundingMemberSince: previousFoundingMemberSince,
         })
      );
      mockUserRepository.updateFoundingMemberStatus.mockResolvedValue(
         makeUser({ isVerified: false, isFoundingMember: false, foundingMemberSince: null })
      );

      const result = await makeService().toggleFoundingMemberStatus(42);

      expect(mockUserRepository.updateFoundingMemberStatus).toHaveBeenCalledWith(42, false, null);
      expect(result.previousIsFoundingMember).toBe(true);
      expect(result.previousFoundingMemberSince).toBe(previousFoundingMemberSince);
      expect(result.user.isFoundingMember).toBe(false);
   });
});
