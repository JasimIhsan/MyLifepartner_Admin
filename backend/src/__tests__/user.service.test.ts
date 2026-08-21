import { UserService } from "@/services/user.service";
import { IUserRepository, UserWithProfile } from "@/interfaces/repositories/user.repository.interface";
import { ICacheService } from "@/interfaces/services/cache.service.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { S3Service } from "@/services/s3.service";
import prisma from "@/config/prisma";

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
   clearDeviceTokens: jest.fn(),
};

const mockEmailService = {
   sendAccountDeletionEmail: jest.fn(),
};

const mockCacheService = {
   getCache: jest.fn(),
   setCache: jest.fn(),
   deleteCache: jest.fn(),
};

const mockReportService = {
   hasUnresolvedReportsAgainstUser: jest.fn(),
};

const makeService = () =>
   new UserService(
      mockUserRepository as unknown as IUserRepository,
      {} as S3Service,
      mockEmailService as unknown as IEmailService,
      mockCacheService as unknown as ICacheService,
      mockReportService as any
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

describe("UserService account deletion requests", () => {
   const mockPrisma = prisma as unknown as {
      user: {
         findUnique: jest.Mock;
         update: jest.Mock;
      };
   };

   beforeEach(() => {
      jest.clearAllMocks();
   });

   it("marks deletion request pending without suspending the user", async () => {
      mockCacheService.getCache.mockResolvedValue(JSON.stringify({ userId: 42, reason: "No longer needed" }));
      mockUserRepository.findById.mockResolvedValue(makeUser());
      mockPrisma.user.update.mockResolvedValue(makeUser());
      mockUserRepository.clearDeviceTokens.mockResolvedValue(undefined);

      await expect(makeService().verifyAccountDeletion("valid-token")).resolves.toBe(42);

      expect(mockPrisma.user.update).toHaveBeenCalledWith({
         where: { id: 42 },
         data: {
            isDeleteRequested: true,
            deleteRequestedAt: expect.any(Date),
            deleteRequestStatus: "PENDING",
            deleteRequestReason: "No longer needed",
         },
      });
      expect(mockPrisma.user.update.mock.calls[0][0].data).not.toHaveProperty("isSuspended");
      expect(mockPrisma.user.update.mock.calls[0][0].data).not.toHaveProperty("suspendedAt");
      expect(mockCacheService.deleteCache).toHaveBeenCalled();
      expect(mockUserRepository.clearDeviceTokens).toHaveBeenCalledWith(42);
   });

   it("rejects deletion request without changing suspension state", async () => {
      mockPrisma.user.findUnique.mockResolvedValue(makeUser({ deleteRequestStatus: "PENDING", isSuspended: true }));
      mockPrisma.user.update.mockResolvedValue(makeUser({ deleteRequestStatus: "REJECTED", isSuspended: true }));

      await expect(makeService().rejectDeletionRequest(42, 7)).resolves.toBeUndefined();

      expect(mockPrisma.user.update).toHaveBeenCalledWith({
         where: { id: 42 },
         data: {
            deleteRequestStatus: "REJECTED",
            deleteRequestReason: null,
         },
      });
      expect(mockPrisma.user.update.mock.calls[0][0].data).not.toHaveProperty("isSuspended");
      expect(mockPrisma.user.update.mock.calls[0][0].data).not.toHaveProperty("suspendedAt");
   });
});
