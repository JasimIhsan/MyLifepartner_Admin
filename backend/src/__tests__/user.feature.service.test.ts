import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { SwipeAction } from "@/interfaces/services/match.service.interface";
import { UserFeatureService } from "@/services/user/user.feature.service";
import { ApiError } from "@/utils/ApiError";

const makeFeatureAccessUser = (overrides = {}) => ({
   id: 42,
   isFoundingMember: false,
   isBanned: false,
   isSuspended: false,
   isDeleted: false,
   isDeleteRequested: false,
   deleteRequestStatus: null,
   ...overrides,
});

const makeFeatures = (overrides = {}) => ({
   id: 1,
   userId: 42,
   isProfileBlurEnabled: false,
   maxInterests: 0,
   interests: 0,
   maxVideoCallMinutes: 0,
   videoCallMinutes: 0,
   maxAudioCallMinutes: 0,
   audioCallMinutes: 0,
   maxMessages: 0,
   messages: 0,
   createdAt: new Date(),
   updatedAt: new Date(),
   ...overrides,
});

const mockFeatureRepository = {
   findByUserId: jest.fn(),
   create: jest.fn(),
   update: jest.fn(),
   delete: jest.fn(),
};

const mockUserRepository = {
   findFeatureAccessStatusById: jest.fn(),
};

function makeService() {
   return new UserFeatureService(
      mockFeatureRepository as unknown as IUserFeatureRepository,
      mockUserRepository as unknown as IUserRepository
   );
}

describe("UserFeatureService founding-member access", () => {
   beforeEach(() => {
      jest.clearAllMocks();
      mockUserRepository.findFeatureAccessStatusById.mockResolvedValue(makeFeatureAccessUser());
   });

   it("keeps normal limit checks for users who have reached their free interest limit", async () => {
      mockFeatureRepository.findByUserId.mockResolvedValue(makeFeatures({ maxInterests: 1, interests: 1 }));

      const service = makeService();

      await expect(service.checkSwipeAccess(42, SwipeAction.RIGHT)).resolves.toBe(false);
      await expect(service.consumeSwipe(42, SwipeAction.RIGHT)).rejects.toMatchObject({
         statusCode: 402,
      } satisfies Partial<ApiError>);
      expect(mockFeatureRepository.findByUserId).toHaveBeenCalled();
      expect(mockFeatureRepository.update).not.toHaveBeenCalled();
   });

   it("keeps normal usage consumption for users with available premium limits", async () => {
      mockFeatureRepository.findByUserId.mockResolvedValue(makeFeatures({ maxMessages: 10, messages: 2 }));
      mockFeatureRepository.update.mockResolvedValue(makeFeatures({ maxMessages: 10, messages: 3 }));

      const service = makeService();

      await service.consumeMessage(42);

      expect(mockFeatureRepository.findByUserId).toHaveBeenCalledWith(42);
      expect(mockFeatureRepository.update).toHaveBeenCalledWith(42, { messages: 3 });
   });

   it("allows founding members without reading or updating UserFeature usage", async () => {
      mockUserRepository.findFeatureAccessStatusById.mockResolvedValue(makeFeatureAccessUser({ isFoundingMember: true }));

      const service = makeService();

      await expect(service.checkSwipeAccess(42, SwipeAction.RIGHT)).resolves.toBe(true);
      await expect(service.checkMessageAccess(42)).resolves.toBe(true);
      await expect(service.checkCallAccess(42, "video", 60)).resolves.toBeUndefined();
      await expect(service.consumeSwipe(42, SwipeAction.RIGHT)).resolves.toBeUndefined();
      await expect(service.consumeMessage(42)).resolves.toBeUndefined();
      await expect(service.consumeCallDuration(42, "audio", 60)).resolves.toBeUndefined();

      expect(mockFeatureRepository.findByUserId).not.toHaveBeenCalled();
      expect(mockFeatureRepository.update).not.toHaveBeenCalled();
      expect(mockFeatureRepository.create).not.toHaveBeenCalled();
   });

   it("returns virtual unlimited features for founding members", async () => {
      mockUserRepository.findFeatureAccessStatusById.mockResolvedValue(makeFeatureAccessUser({ isFoundingMember: true }));

      const service = makeService();
      const features = await service.getUserFeatures(42);

      expect(features).toMatchObject({
         userId: 42,
         isProfileBlurEnabled: true,
         isFoundingMember: true,
         isUnlimited: true,
      });
      expect(features?.maxMessages).toBe(Number.MAX_SAFE_INTEGER);
      expect(mockFeatureRepository.findByUserId).not.toHaveBeenCalled();
   });

   it("falls back to UserFeature limits immediately after founding status is revoked", async () => {
      mockUserRepository.findFeatureAccessStatusById.mockResolvedValue(makeFeatureAccessUser({ isFoundingMember: false }));
      mockFeatureRepository.findByUserId.mockResolvedValue(makeFeatures({ maxMessages: 1, messages: 1 }));

      const service = makeService();

      await expect(service.consumeMessage(42)).rejects.toMatchObject({ statusCode: 402 } satisfies Partial<ApiError>);
      expect(mockFeatureRepository.findByUserId).toHaveBeenCalledWith(42);
   });

   it("does not apply founding-member bypass for banned, suspended, deleted, or pending-deletion accounts", async () => {
      const restrictedStates = [
         { isBanned: true },
         { isSuspended: true },
         { isDeleted: true },
         { isDeleteRequested: true, deleteRequestStatus: "PENDING" },
      ];

      for (const state of restrictedStates) {
         jest.clearAllMocks();
         mockUserRepository.findFeatureAccessStatusById.mockResolvedValue(makeFeatureAccessUser({ isFoundingMember: true, ...state }));
         mockFeatureRepository.findByUserId.mockResolvedValue(null);

         const service = makeService();

         await expect(service.checkMessageAccess(42)).resolves.toBe(false);
         expect(mockFeatureRepository.findByUserId).toHaveBeenCalledWith(42);
      }
   });
});
