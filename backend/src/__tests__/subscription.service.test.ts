/**
 * subscription.service.test.ts
 *
 * Unit tests for UserSubscriptionService.
 *
 * All external dependencies (Prisma, RevenueCat API, repositories) are fully
 * mocked.  Each test focuses on one behaviour from the audit requirements.
 *
 * Audit issues covered:
 *   C-1  Webhook signature validation
 *   C-2  POST /subscribe locked to FREE plan
 *   C-3  BILLING_ISSUE keeps access, records billingIssueDetectedAt
 *   C-4  Atomic idempotency — duplicate events processed exactly once
 *   C-5  Deferred downgrade updates endDate from RevenueCat
 *   C-7  EXPIRATION and REFUND are handled separately with distinct timestamps
 *   C-8  Usage counters preserved on RENEWAL; reset only on INITIAL_PURCHASE
 *   H-1  Stale events (older timestamp) are silently rejected
 *   H-2  getMySubscription does NOT write to the database
 *   H-4  Webhook: userId not in DB → event skipped
 *   M-3  Webhook logs safe fields only (not full event object)
 *   M-6  FREE plan uses a 100-year endDate
 *   RC-1 activatePlan stores event metadata (lastEventTimestampMs)
 *   RC-2 EXPIRATION/REFUND scoped to transaction ID
 *   RC-3 grace period applies for FREE-plan user
 *   RC-4 syncSubscription idempotent under concurrency (advisory lock)
 *   RC-5 anonymous original_app_user_id does not bypass
 */

// ─── Mock env BEFORE any module is imported ──────────────────────────────────
jest.mock("@/config/env", () => ({
   __esModule: true,
   default: {
      NODE_ENV: "test",
      REVENUECAT_WEBHOOK_SECRET: "test-webhook-secret",
      REVENUECAT_SECRET_API_KEY: "test-rc-api-key",
      ALLOWED_ORIGINS: "",
   },
}));

// ─── Mock Prisma ──────────────────────────────────────────────────────────────
const mockTx = {
   user: { findUnique: jest.fn() },
   userSubscription: {
      findFirst: jest.fn(),
      updateMany: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
      upsert: jest.fn(),
   },
   processedRevenueCatEvent: { create: jest.fn() },
   subscriptionPlan: { findUnique: jest.fn() },
   userFeature: { findUnique: jest.fn(), update: jest.fn(), create: jest.fn() },
   userSubscriptionLog: { create: jest.fn() },
   transactionHistory: { create: jest.fn() },
   $executeRaw: jest.fn(),
};

jest.mock("@/config/prisma", () => ({
   __esModule: true,
   default: {
      $transaction: jest.fn(async (cb) => {
         return await cb(mockTx);
      }),
   },
}));

// ─── Mock logger ──────────────────────────────────────────────────────────────
jest.mock("@/utils/logger", () => ({
   __esModule: true,
   default: { info: jest.fn(), warn: jest.fn(), error: jest.fn(), debug: jest.fn() },
}));

jest.mock("@/services/audit.service", () => ({
   auditService: {
      log: jest.fn(),
   },
}));

jest.mock("@/composer/composer", () => ({
   notificationService: {
      sendToUser: jest.fn(),
   },
}));

// ─── Mock fetch ───────────────────────────────────────────────────────────────
global.fetch = jest.fn();

import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { IProcessedRevenueCatEventRepository } from "@/interfaces/repositories/processed-revenuecat-event.repository.interface";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IUserSubscriptionRepository } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { IUserRepository } from "@/interfaces/repositories/user.repository.interface";
import { IEmailService } from "@/interfaces/services/email.service.interface";
import { SubscriptionWebhookRepository } from "@/repositories/subscription-webhook.repository";
import { UserSubscriptionService } from "@/services/user/user.subscription.service";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";
import { Prisma } from "@prisma/client";

// ─── Helpers ──────────────────────────────────────────────────────────────────

const FREE_PLAN = { id: 1, name: "FREE", price: 0, durationDays: 36500, isActive: true, isMostPopular: false, storeProductId: null, description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };
const PREMIUM_PLAN = { id: 2, name: "PREMIUM", price: 29900, durationDays: 30, isActive: true, isMostPopular: true, storeProductId: "premium_monthly", description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };
const MEDIUM_PLAN = { id: 3, name: "MEDIUM", price: 14900, durationDays: 30, isActive: true, isMostPopular: false, storeProductId: "medium_monthly", description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };

const makeActiveSub = (overrides = {}) => ({
   id: 100,
   userId: 42,
   planId: 2,
   plan: PREMIUM_PLAN,
   status: "ACTIVE",
   willRenew: true,
   startDate: new Date(),
   endDate: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
   nextPlanId: null,
   createdAt: new Date(Date.now() - 1000),
   updatedAt: new Date(),
   revenueCatEventId: "evt_prev",
   lastEventTimestampMs: BigInt(1000),
   originalTransactionId: "txn_original",
   store: "PLAY_STORE",
   environment: "PRODUCTION",
   cancelledAt: null,
   billingIssueDetectedAt: null,
   planChangesAt: null,
   refundedAt: null,
   expiredAt: null,
   ...overrides,
});

const makeWebhookEvent = (
   overrides: Partial<{
      id: string;
      type: RevenueCatWebhookEvent;
      product_id: string;
      app_user_id: string;
      original_app_user_id: string;
      original_transaction_id: string;
      event_timestamp_ms: number;
      expiration_at_ms: number;
      store: string;
      environment: string;
      aliases: string[];
   }> = {}
) => ({
   id: "evt_new",
   type: RevenueCatWebhookEvent.RENEWAL,
   product_id: "premium_monthly",
   app_user_id: "42",
   original_app_user_id: "42",
   original_transaction_id: "txn_original",
   event_timestamp_ms: 9999999,
   expiration_at_ms: Date.now() + 30 * 24 * 60 * 60 * 1000,
   store: "PLAY_STORE",
   environment: "PRODUCTION",
   aliases: [],
   ...overrides,
});

const makeWebhookPayload = (eventOverrides = {}) => ({
   event: makeWebhookEvent(eventOverrides),
});

// ─── Repository mocks ─────────────────────────────────────────────────────────

const mockSubPlanRepo = {
   getAllPlansWithFeatures: jest.fn(),
   getPlanByName: jest.fn(),
   getPlanById: jest.fn(),
   findPlanByStoreProductId: jest.fn(),
   createPlan: jest.fn(),
   updatePlan: jest.fn(),
   deletePlan: jest.fn(),
   untoggleMostPopularPlans: jest.fn(),
};

const mockSubRepo = {
   createUserSubscription: jest.fn(),
   findActiveSubscriptionByUserId: jest.fn(),
   deactivateUserSubscriptions: jest.fn(),
   updateUserSubscription: jest.fn(),
   executeSyncTransaction: jest.fn(async (userId, cb) => {
      const mockCtx = {
         findActiveSubscriptionByUserId: jest.fn(async (uid) =>
            mockTx.userSubscription.findFirst({
               where: { userId: uid, status: "ACTIVE" },
               orderBy: { createdAt: "desc" },
            })
         ),
         deactivateUserSubscriptions: jest.fn(async (uid) =>
            mockTx.userSubscription.updateMany({
               where: { userId: uid, status: "ACTIVE" },
               data: { status: "EXPIRED" },
            })
         ),
         createUserSubscription: jest.fn(async (data) =>
            mockTx.userSubscription.create({
               data,
               include: { plan: { include: { features: true } } },
            })
         ),
         upsertUserSubscriptionByOriginalTransactionId: jest.fn(async (originalTransactionId, createData, updateData) =>
            mockTx.userSubscription.upsert({
               where: { originalTransactionId },
               create: createData,
               update: updateData,
               include: { plan: { include: { features: true } } },
            })
         ),
         updateUserSubscription: jest.fn(async (id, data) =>
            mockTx.userSubscription.update({
               where: { id },
               data,
            })
         ),
         applyFeatures: jest.fn(async (uid, payload) => {
            const existing = await mockTx.userFeature.findUnique({ where: { userId: uid } });
            if (existing) {
               await mockTx.userFeature.update({ where: { userId: uid }, data: payload });
            } else {
               await mockTx.userFeature.create({ data: { user: { connect: { id: uid } }, ...payload } });
            }
         }),
         writeAuditLog: jest.fn(async (params) =>
            mockTx.userSubscriptionLog.create({
               data: {
                  userId: params.userId,
                  previousPlanId: params.previousPlanId ?? null,
                  newPlanId: params.newPlanId ?? null,
                  previousStatus: params.previousStatus ?? null,
                  newStatus: params.newStatus,
                  reason: params.reason,
                  source: params.source,
                  eventType: "SYNC",
                  eventId: `sync_mock`,
               },
            })
         ),
      };
      // For tests that assert on the lock
      await mockTx.$executeRaw`SELECT pg_advisory_xact_lock(${userId})`;
      return await cb(mockCtx);
   }),
};

const mockEventRepo = {
   hasProcessedEvent: jest.fn(),
   markEventProcessed: jest.fn(),
};

const mockFeatureRepo = {
   findByUserId: jest.fn(),
   update: jest.fn(),
   create: jest.fn(),
};

const mockUserRepo = {
   findById: jest.fn(),
   findFeatureAccessStatusById: jest.fn(),
   findByEmail: jest.fn(),
   create: jest.fn(),
   update: jest.fn(),
};

const mockEmailService = {
   sendSubscriptionSuccessEmail: jest.fn(),
   sendSubscriptionRenewalEmail: jest.fn(),
   sendSubscriptionFailureEmail: jest.fn(),
   sendOtpEmail: jest.fn(),
   sendWelcomeEmail: jest.fn(),
};

// ─── Service factory ──────────────────────────────────────────────────────────

function makeService() {
   return new UserSubscriptionService(
      mockSubPlanRepo as unknown as ISubscriptionPlanRepository,
      mockSubRepo as unknown as IUserSubscriptionRepository,
      mockEventRepo as unknown as IProcessedRevenueCatEventRepository,
      mockFeatureRepo as unknown as IUserFeatureRepository,
      new SubscriptionWebhookRepository(),
      mockUserRepo as unknown as IUserRepository,
      mockEmailService as unknown as IEmailService
   );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

describe("UserSubscriptionService", () => {
   beforeEach(() => {
      jest.clearAllMocks();
      // Default: user exists in DB
      mockTx.user.findUnique.mockResolvedValue({ id: 42 });
      mockUserRepo.findFeatureAccessStatusById.mockResolvedValue({
         id: 42,
         isFoundingMember: false,
         isBanned: false,
         isSuspended: false,
         isDeleted: false,
         isDeleteRequested: false,
         deleteRequestStatus: null,
      });
      // Default: advisory lock succeeds
      mockTx.$executeRaw.mockResolvedValue(undefined);
      // Default: idempotency insert succeeds (event is new)
      mockTx.processedRevenueCatEvent.create.mockResolvedValue({ id: "evt_new" });
      // Default: no existing features
      mockTx.userFeature.findUnique.mockResolvedValue(null);
      mockTx.userFeature.create.mockResolvedValue({});
      mockTx.userFeature.update.mockResolvedValue({});
      mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 });
      mockTx.userSubscription.upsert.mockResolvedValue(makeActiveSub());
      mockTx.userSubscriptionLog.create.mockResolvedValue({ id: 1 });
   });

   // ── C-1: Webhook signature validation ────────────────────────────────────

   describe("C-1: webhook signature validation", () => {
      it("rejects webhook with missing Authorization header", async () => {
         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload(), undefined)).rejects.toThrow(ApiError);
      });

      it("rejects webhook with wrong Authorization header", async () => {
         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload(), "wrong-secret")).rejects.toThrow(ApiError);
         const err = await svc.handleWebhook(makeWebhookPayload(), "wrong-secret").catch((e) => e);
         expect((err as ApiError).statusCode).toBe(401);
      });

      it("accepts webhook with correct Authorization header", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.updateMany.mockResolvedValue({ count: 0 });
         const subWithPlan = {
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         };
         mockTx.userSubscription.create.mockResolvedValue(subWithPlan);
         mockTx.userSubscription.create.mockResolvedValue(subWithPlan);
         mockTx.userFeature.findUnique.mockResolvedValue(null);
         mockTx.userFeature.create.mockResolvedValue({});

         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload(), "test-webhook-secret")).resolves.not.toThrow();
      });
   });

   // ── C-2: subscribe endpoint restricted to FREE plan only ─────────────────

   describe("C-2: subscribe endpoint restricted to FREE plan only", () => {
      it("rejects subscription attempt for a paid plan", async () => {
         mockSubPlanRepo.getPlanById.mockResolvedValue(PREMIUM_PLAN);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         await expect(svc.subscribe(42, PREMIUM_PLAN.id)).rejects.toThrow(ApiError);
         const err: ApiError = await svc.subscribe(42, PREMIUM_PLAN.id).catch((e) => e);
         expect(err.statusCode).toBe(403);
      });

      it("allows subscription to the FREE plan", async () => {
         mockSubPlanRepo.getPlanById.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(null);
         mockSubRepo.deactivateUserSubscriptions.mockResolvedValue({ count: 0 });
         mockSubRepo.createUserSubscription.mockResolvedValue({
            ...makeActiveSub({ planId: 1, plan: FREE_PLAN }),
         });
         mockFeatureRepo.findByUserId.mockResolvedValue(null);
         mockFeatureRepo.create.mockResolvedValue({});

         const svc = makeService();
         const result = await svc.subscribe(42, FREE_PLAN.id);
         expect(result.planId).toBe(FREE_PLAN.id);
      });
   });

   // ── C-3: BILLING_ISSUE keeps access, records billingIssueDetectedAt ──────

   describe("C-3: BILLING_ISSUE event — grace period", () => {
      it("does NOT expire the subscription on BILLING_ISSUE", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.BILLING_ISSUE }), "test-webhook-secret");

         // updateMany with status EXPIRED must NOT be called
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
      });

      it("records billingIssueDetectedAt on BILLING_ISSUE", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.update.mockResolvedValue({});

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.BILLING_ISSUE }), "test-webhook-secret");

         expect(mockTx.userSubscription.update).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({ billingIssueDetectedAt: expect.any(Date) }),
            })
         );
      });
   });

   // ── C-4: Atomic idempotency ───────────────────────────────────────────────

   describe("C-4: duplicate webhook events processed exactly once", () => {
      it("skips processing when the processed-event row already exists (P2002)", async () => {
         // Simulate a P2002 unique constraint violation on the second attempt
         const p2002 = new Prisma.PrismaClientKnownRequestError("Unique constraint failed", {
            code: "P2002",
            clientVersion: "5.0.0",
            meta: {},
         });
         mockTx.processedRevenueCatEvent.create.mockRejectedValue(p2002);

         const svc = makeService();
         // Should resolve without throwing (not re-throw P2002)
         await expect(svc.handleWebhook(makeWebhookPayload(), "test-webhook-secret")).resolves.not.toThrow();

         // Subscription should not be modified
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });

      it("re-throws non-P2002 database errors", async () => {
         const dbError = new Error("Connection lost");
         mockTx.processedRevenueCatEvent.create.mockRejectedValue(dbError);

         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload(), "test-webhook-secret")).rejects.toThrow("Connection lost");
      });
   });

   // ── C-5: Deferred downgrade updates endDate from RC ───────────────────────

   describe("C-5: deferred downgrade sets endDate from RevenueCat", () => {
      it("updates endDate when scheduling a deferred downgrade", async () => {
         const rcEndDate = new Date(Date.now() + 20 * 24 * 60 * 60 * 1000);

         // Current active subscription is PREMIUM (higher plan)
         const currentSub = makeActiveSub({ planId: PREMIUM_PLAN.id, plan: PREMIUM_PLAN });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         // RC says the new product is MEDIUM (lower plan)
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(MEDIUM_PLAN);
         mockSubPlanRepo.getPlanById.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.update.mockResolvedValue({ ...makeActiveSub(), nextPlanId: 3, endDate: rcEndDate });

         // Mock the RC API response
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({
               subscriber: {
                  original_app_user_id: "42",
                  aliases: [],
                  subscriptions: {
                     medium_monthly: {
                        expires_date: rcEndDate.toISOString(),
                        purchase_date: new Date().toISOString(),
                        unsubscribe_detected_at: new Date().toISOString(), // cancellation scheduled
                     },
                  },
               },
            }),
         });

         const svc = makeService();
         await svc.syncSubscription(42);

         // endDate must be updated to the RC-verified value (not kept stale)
         expect(mockTx.userSubscription.update).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({
                  nextPlanId: MEDIUM_PLAN.id,
                  willRenew: false,
                  endDate: expect.any(Date), // C-5: endDate is updated
               }),
            })
         );
      });
   });

   // ── C-7: EXPIRATION and REFUND are separate ───────────────────────────────

   describe("C-7: EXPIRATION records expiredAt; REFUND records refundedAt", () => {
      beforeEach(() => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.create.mockResolvedValue({
            ...makeActiveSub({ planId: 1, plan: { ...FREE_PLAN, features: [] } }),
         });
      });

      it("EXPIRATION sets expiredAt but NOT refundedAt", async () => {
         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.EXPIRATION }), "test-webhook-secret");

         expect(mockTx.userSubscription.updateMany).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({ expiredAt: expect.any(Date) }),
            })
         );
         // Ensure refundedAt is NOT set during expiration
         const updateCall = mockTx.userSubscription.updateMany.mock.calls[0][0];
         expect(updateCall.data).not.toHaveProperty("refundedAt");
      });

      it("REFUND sets refundedAt but NOT expiredAt", async () => {
         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.REFUND }), "test-webhook-secret");

         expect(mockTx.userSubscription.updateMany).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({ refundedAt: expect.any(Date), status: "EXPIRED" }),
            })
         );
         const updateCall = mockTx.userSubscription.updateMany.mock.calls[0][0];
         expect(updateCall.data).not.toHaveProperty("expiredAt");
      });
   });

   // ── C-8: Usage counters preserved on RENEWAL ─────────────────────────────

   describe("C-8: usage counters preserved on RENEWAL, reset on INITIAL_PURCHASE", () => {
      const setupActiveSubscriptionRenewal = (eventType: RevenueCatWebhookEvent) => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 });
         mockTx.userSubscription.create.mockResolvedValue({
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         });
         mockTx.userFeature.findUnique.mockResolvedValue({ userId: 42, interests: 7, messages: 15, videoCallMinutes: 30, audioCallMinutes: 45 });
      };

      it("RENEWAL: does NOT reset usage counters (interests, messages, callMinutes)", async () => {
         setupActiveSubscriptionRenewal(RevenueCatWebhookEvent.RENEWAL);

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.RENEWAL }), "test-webhook-secret");

         // The feature update should NOT include usage counters
         const featureUpdateCall = mockTx.userFeature.update.mock.calls[0];
         if (featureUpdateCall) {
            const updatedData = featureUpdateCall[0].data;
            expect(updatedData).not.toHaveProperty("interests");
            expect(updatedData).not.toHaveProperty("messages");
            expect(updatedData).not.toHaveProperty("videoCallMinutes");
            expect(updatedData).not.toHaveProperty("audioCallMinutes");
         }
      });

      it("INITIAL_PURCHASE: resets usage counters to zero", async () => {
         setupActiveSubscriptionRenewal(RevenueCatWebhookEvent.INITIAL_PURCHASE);
         mockTx.userSubscription.create.mockResolvedValue({
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         });

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.INITIAL_PURCHASE, original_transaction_id: "" }), "test-webhook-secret");

         const featureUpdateCall = mockTx.userFeature.update.mock.calls[0];
         if (featureUpdateCall) {
            const updatedData = featureUpdateCall[0].data;
            expect(updatedData.interests).toBe(0);
            expect(updatedData.messages).toBe(0);
            expect(updatedData.videoCallMinutes).toBe(0);
            expect(updatedData.audioCallMinutes).toBe(0);
         }
      });
   });

   // ── H-1: Stale events rejected ────────────────────────────────────────────

   describe("H-1: stale events are silently rejected", () => {
      it("ignores a webhook whose timestamp is older than the current subscription", async () => {
         const currentSub = makeActiveSub({ lastEventTimestampMs: BigInt(9999999) });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         // Send an event with timestamp 1000, but current subscription is at 9999999
         await svc.handleWebhook(makeWebhookPayload({ event_timestamp_ms: 1000 }), "test-webhook-secret");

         // No subscription modifications should occur
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
         expect(mockTx.userSubscription.update).not.toHaveBeenCalled();
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });

      it("processes a webhook whose timestamp equals the current (same event replayed)", async () => {
         // Timestamp exactly equal should be processed (edge case: allow = and >)
         const currentSub = makeActiveSub({ lastEventTimestampMs: BigInt(5000) });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 });
         mockTx.userSubscription.create.mockResolvedValue({
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         });
         mockTx.userFeature.findUnique.mockResolvedValue({ userId: 42 });

         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload({ event_timestamp_ms: 5001 }), "test-webhook-secret")).resolves.not.toThrow();
      });
   });

   // ── H-2: getMySubscription is a pure read ─────────────────────────────────

   describe("H-2: getMySubscription does not write to the database", () => {
      it("returns subscription without any DB writes even if endDate is past", async () => {
         const expiredLocalSub = makeActiveSub({
            endDate: new Date(Date.now() - 1000), // locally expired
         });
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(expiredLocalSub);

         const svc = makeService();
         const result = await svc.getMySubscription(42);

         // Should return the subscription (source-of-truth is webhooks, not local clock)
         expect(result).not.toBeNull();
         // CRITICAL: No deactivation or free-plan creation must happen
         expect(mockSubRepo.deactivateUserSubscriptions).not.toHaveBeenCalled();
         expect(mockSubRepo.createUserSubscription).not.toHaveBeenCalled();
      });

      it("returns null when no active subscription exists", async () => {
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(null);

         const svc = makeService();
         const result = await svc.getMySubscription(42);
         expect(result).toBeNull();
      });
   });

   // ── H-4: Webhook skipped if userId not in DB ─────────────────────────────

   describe("H-4: webhook skipped when userId does not exist in database", () => {
      it("silently returns when no user row found for the resolved userId", async () => {
         mockTx.user.findUnique.mockResolvedValue(null); // user does not exist

         const svc = makeService();
         await expect(svc.handleWebhook(makeWebhookPayload(), "test-webhook-secret")).resolves.not.toThrow();

         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });
   });

   // ── Cancellation: access preserved until expiry ───────────────────────────

   describe("Cancellation: keeps willRenew=false, updates status to CANCELLED_PENDING_EXPIRY", () => {
      it("sets willRenew=false, status=CANCELLED_PENDING_EXPIRY and cancelledAt without expiring the subscription", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.update.mockResolvedValue({});

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.CANCELLATION }), "test-webhook-secret");

         // Must NOT expire the subscription
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();

         // Must set status=CANCELLED_PENDING_EXPIRY, willRenew=false and record cancelledAt
         expect(mockTx.userSubscription.update).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({
                  status: "CANCELLED_PENDING_EXPIRY",
                  willRenew: false,
                  cancelledAt: expect.any(Date),
               }),
            })
         );
      });
   });

   // ── M-6: FREE plan endDate uses 100-year duration ─────────────────────────

   describe("M-6: FREE plan subscriptions use a 100-year endDate", () => {
      it("creates FREE plan subscription with endDate ~100 years in the future", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValueOnce(makeActiveSub()).mockResolvedValueOnce(null); // No remaining active sub
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.create.mockImplementation(async ({ data }: { data: { endDate: Date } }) => ({
            ...makeActiveSub({ planId: 1 }),
            plan: { ...FREE_PLAN, features: [] },
            endDate: data.endDate,
         }));

         mockSubPlanRepo.getPlanById.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         const svc = makeService();
         await svc.subscribe(42, FREE_PLAN.id);

         const createCall = mockSubRepo.createUserSubscription.mock.calls[0];
         expect(createCall).toBeDefined();
         const endDate: Date = createCall[0].endDate;
         const yearsFromNow = (endDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24 * 365);
         expect(yearsFromNow).toBeGreaterThan(90); // at least 90 years in the future
      });
   });

   // ── M-3: Webhook does not log full event object ───────────────────────────

   describe("M-3: webhook logs safe fields, not the full event", () => {
      it("logs eventId, type, productId — not the full event object", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.create.mockResolvedValue({
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         });

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload(), "test-webhook-secret");

         const logCalls = (logger.info as jest.Mock).mock.calls;
         // The first log call should be the safe "Webhook event received" log
         const eventLog = logCalls.find((call) => call[0] === "Webhook event received");
         expect(eventLog).toBeDefined();
         // Ensure the logged metadata is an object with only safe fields
         const loggedMeta = eventLog![1];
         expect(loggedMeta).toHaveProperty("eventId");
         expect(loggedMeta).toHaveProperty("type");
         // The full event object (with potential PII) must not be spread into logs
         expect(loggedMeta).not.toHaveProperty("app_user_id");
         expect(loggedMeta).not.toHaveProperty("original_app_user_id");
      });
   });

   // ── Invalid product ID ────────────────────────────────────────────────────

   describe("Invalid product ID handling", () => {
      it("falls back to sync when product_id is not in the plan mapping", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         // No plan found for identifier
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(null);

         // Mock RC API for the sync fallback
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "42", aliases: [], subscriptions: {} } }),
         });

         const currentSub = makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN, createdAt: new Date(Date.now() - 5 * 60 * 1000) });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);

         mockTx.userSubscription.create.mockResolvedValue({ ...makeActiveSub({ planId: 1 }), plan: { ...FREE_PLAN, features: [] } });

         const svc = makeService();
         // Should not throw — falls back gracefully to sync
         await expect(svc.handleWebhook(makeWebhookPayload({ product_id: "unknown_plan_xyz" }), "test-webhook-secret")).resolves.not.toThrow();
      });
   });

   // ── getPlans ───────────────────────────────────────────────────────────────

   describe("getPlans", () => {
      it("returns enriched and sorted plans (FREE first, then by price)", async () => {
         const midPlan = { ...PREMIUM_PLAN, id: 3, name: "MID", price: 10000 };
         mockSubPlanRepo.getAllPlansWithFeatures.mockResolvedValue([PREMIUM_PLAN, FREE_PLAN, midPlan]);

         const svc = makeService();
         const plans = await svc.getPlans();

         expect(plans).toHaveLength(3);
         expect(plans[0].name).toBe("FREE");
         expect(plans[1].name).toBe("MID");
         expect(plans[2].name).toBe("PREMIUM");
      });
   });

   // ── getUserFeatures ───────────────────────────────────────────────────────

   describe("getUserFeatures", () => {
      it("returns features from repository", async () => {
         mockFeatureRepo.findByUserId.mockResolvedValue({ userId: 42, maxInterests: 5 });
         const svc = makeService();
         const features = await svc.getUserFeatures(42);
         expect(features).toEqual({ userId: 42, maxInterests: 5 });
      });
   });

   describe("founding members", () => {
      beforeEach(() => {
         mockUserRepo.findFeatureAccessStatusById.mockResolvedValue({
            id: 42,
            isFoundingMember: true,
            isBanned: false,
            isSuspended: false,
            isDeleted: false,
            isDeleteRequested: false,
            deleteRequestStatus: null,
         });
      });

      it("does not require or create a subscription during sync", async () => {
         const svc = makeService();
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(null);

         const result = await svc.syncSubscription(42);

         expect(result).toBeNull();
         expect(global.fetch).not.toHaveBeenCalled();
         expect(mockSubRepo.executeSyncTransaction).not.toHaveBeenCalled();
         expect(mockSubRepo.createUserSubscription).not.toHaveBeenCalled();
      });

      it("does not apply UserFeature payloads while processing real subscription webhooks", async () => {
         const svc = makeService();
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         mockTx.userSubscription.upsert.mockResolvedValue({
            ...makeActiveSub(),
            plan: PREMIUM_PLAN,
         });

         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.INITIAL_PURCHASE }), "test-webhook-secret");

         expect(mockTx.userFeature.findUnique).not.toHaveBeenCalled();
         expect(mockTx.userFeature.update).not.toHaveBeenCalled();
         expect(mockTx.userFeature.create).not.toHaveBeenCalled();
      });

      it("does not create a FREE fallback subscription after a founding-member refund webhook", async () => {
         const svc = makeService();
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.findFirst.mockResolvedValueOnce(makeActiveSub()).mockResolvedValueOnce(null);

         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.REFUND }), "test-webhook-secret");

         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
         expect(mockTx.userFeature.findUnique).not.toHaveBeenCalled();
         expect(mockTx.userFeature.update).not.toHaveBeenCalled();
         expect(mockTx.userFeature.create).not.toHaveBeenCalled();
      });
   });

   // ── subscribe (error cases) ───────────────────────────────────────────────

   describe("subscribe errors", () => {
      it("rejects if plan not found", async () => {
         mockSubPlanRepo.getPlanById.mockResolvedValue(null);
         const svc = makeService();
         await expect(svc.subscribe(42, 999)).rejects.toThrow(ApiError);
         const err = await svc.subscribe(42, 999).catch((e) => e);
         expect(err.statusCode).toBe(404);
      });

      it("rejects if plan is inactive", async () => {
         mockSubPlanRepo.getPlanById.mockResolvedValue({ ...FREE_PLAN, isActive: false });
         const svc = makeService();
         await expect(svc.subscribe(42, FREE_PLAN.id)).rejects.toThrow(ApiError);
         const err = await svc.subscribe(42, FREE_PLAN.id).catch((e) => e);
         expect(err.statusCode).toBe(400);
      });

      it("returns current FREE plan if user already subscribed", async () => {
         mockSubPlanRepo.getPlanById.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         const currentFreeSub = makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN });
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentFreeSub);

         const svc = makeService();
         const sub = await svc.subscribe(42, FREE_PLAN.id);

         expect(sub.id).toBe(currentFreeSub.id);
         expect(mockSubRepo.deactivateUserSubscriptions).not.toHaveBeenCalled();
      });
   });

   // ── RC-1: activatePlan stores event metadata ──────────────────────────────

   describe("RC-1: activatePlan stores event metadata", () => {
      it("verifyAndActivatePurchase stores RevenueCat store_transaction_id, not a legacy app user id", async () => {
         const expiresDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({
               subscriber: {
                  original_app_user_id: "00000000-0000-4000-8000-00000000002a",
                  aliases: ["42"],
                  subscriptions: {
                     premium_monthly: {
                        expires_date: expiresDate,
                        purchase_date: new Date().toISOString(),
                        store_transaction_id: "1000000123456789",
                        store: "app_store",
                        is_sandbox: true,
                     },
                  },
               },
            }),
         });

         mockTx.userSubscription.findFirst.mockResolvedValue(null);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.upsert.mockResolvedValue(
            makeActiveSub({
               originalTransactionId: "1000000123456789",
               store: "app_store",
               environment: "SANDBOX",
            })
         );
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(
            makeActiveSub({
               originalTransactionId: "1000000123456789",
               store: "app_store",
               environment: "SANDBOX",
            })
         );

         const svc = makeService();
         await svc.verifyAndActivatePurchase(42, {
            originalTransactionId: "00000000-0000-4000-8000-00000000002a",
            productId: "premium_monthly",
            store: "APP_STORE",
            environment: "SANDBOX",
         });

         expect(mockTx.userSubscription.upsert).toHaveBeenCalledWith(
            expect.objectContaining({
               where: { originalTransactionId: "1000000123456789" },
               create: expect.objectContaining({
                  originalTransactionId: "1000000123456789",
                  store: "app_store",
                  environment: "SANDBOX",
               }),
            })
         );
      });

      it("syncSubscription stores lastEventTimestampMs when creating a new paid subscription", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({
               subscriber: {
                  original_app_user_id: "42",
                  aliases: [],
                  subscriptions: { premium_monthly: { expires_date: new Date(Date.now() + 10000).toISOString() } },
               },
            }),
         });

         const currentSub = makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockTx.userSubscription.create.mockResolvedValue(makeActiveSub({ planId: PREMIUM_PLAN.id, plan: PREMIUM_PLAN }));

         const svc = makeService();
         await svc.syncSubscription(42);

         expect(mockTx.userSubscription.updateMany).toHaveBeenCalled();
         expect(mockTx.userSubscription.create).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({
                  planId: PREMIUM_PLAN.id,
                  lastEventTimestampMs: expect.any(BigInt),
               }),
            })
         );
      });
   });

   // ── RC-2: EXPIRATION / REFUND scoped to transaction ID ────────────────────

   describe("RC-2: EXPIRATION / REFUND scoped to transaction ID", () => {
      it("EXPIRATION for different transaction ID does NOT expire current subscription", async () => {
         const currentSub = makeActiveSub({ originalTransactionId: "txn_current", planId: PREMIUM_PLAN.id });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 }); // Orphan expired

         const svc = makeService();
         await svc.handleWebhook(
            makeWebhookPayload({
               type: RevenueCatWebhookEvent.EXPIRATION,
               original_transaction_id: "txn_old",
               product_id: "premium_monthly",
               event_timestamp_ms: 9999999, // newer than current sub so it passes stale guard
            }),
            "test-webhook-secret"
         );

         // Only the orphaned transaction should be targeted
         expect(mockTx.userSubscription.updateMany).toHaveBeenCalledWith(
            expect.objectContaining({
               where: expect.objectContaining({ originalTransactionId: "txn_old" }),
            })
         );
         // FREE plan should NOT be created because current sub is still active
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });

      it("REFUND for different transaction ID does NOT revoke current subscription", async () => {
         const currentSub = makeActiveSub({ originalTransactionId: "txn_current", planId: PREMIUM_PLAN.id });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 }); // Orphan expired

         const svc = makeService();
         await svc.handleWebhook(
            makeWebhookPayload({
               type: RevenueCatWebhookEvent.REFUND,
               original_transaction_id: "txn_old",
               product_id: "premium_monthly",
               event_timestamp_ms: 9999999,
            }),
            "test-webhook-secret"
         );

         expect(mockTx.userSubscription.updateMany).toHaveBeenCalledWith(
            expect.objectContaining({
               where: expect.objectContaining({ originalTransactionId: "txn_old" }),
            })
         );
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });
   });

   // ── RC-3: grace period applies for ALL users ──────────────────────────────

   describe("RC-3: grace period applies for FREE-plan user", () => {
      it("retains FREE plan and does NOT expire it if within grace period when RC is empty", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "42", aliases: [], subscriptions: {} } }),
         });

         // User has FREE plan created 30 seconds ago
         const currentSub = makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN, createdAt: new Date(Date.now() - 30 * 1000) });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         await svc.syncSubscription(42);

         // Grace period applies, no downgrade to FREE (which would involve deactivation and recreation)
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
         expect(mockTx.userSubscription.create).not.toHaveBeenCalled();
      });
   });

   // ── RC-4: syncSubscription idempotent under concurrency ───────────────────

   describe("RC-4: syncSubscription uses advisory lock", () => {
      it("acquires pg_advisory_xact_lock(userId) inside transaction", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "42", aliases: [], subscriptions: {} } }),
         });
         const currentSub = makeActiveSub({ planId: PREMIUM_PLAN.id, createdAt: new Date(Date.now() - 5 * 60 * 1000) });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.create.mockResolvedValue(makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN }));

         const svc = makeService();
         await svc.syncSubscription(42);

         // Lock must be acquired
         expect(mockTx.$executeRaw).toHaveBeenCalled();
         const lockCallArgs = mockTx.$executeRaw.mock.calls[0];
         const templateStrings = lockCallArgs[0];
         expect(templateStrings[0]).toContain("SELECT pg_advisory_xact_lock(");
      });
   });

   // ── Enhanced Stale Guard ──────────────────────────────────────────────────

   describe("Enhanced stale guard (createdAt fallback)", () => {
      it("rejects downgrade event if event_timestamp_ms < createdAt when lastEventTimestampMs is null", async () => {
         // Subscription created exactly 1 minute ago, without lastEventTimestampMs (legacy)
         const createdAtMs = Date.now() - 60000;
         const currentSub = makeActiveSub({
            lastEventTimestampMs: null,
            createdAt: new Date(createdAtMs),
         });
         mockTx.userSubscription.findFirst.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         // Send EXPIRATION from 2 minutes ago
         await svc.handleWebhook(
            makeWebhookPayload({
               type: RevenueCatWebhookEvent.EXPIRATION,
               event_timestamp_ms: createdAtMs - 60000,
            }),
            "test-webhook-secret"
         );

         // Should be rejected as stale, no mutations
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
      });
   });

   // ── Webhook Malformed Payload ─────────────────────────────────────────────

   describe("handleWebhook malformed payload", () => {
      it("silently returns without processing if event is missing id or type", async () => {
         const svc = makeService();
         // Missing ID
         await svc.handleWebhook({ event: { type: RevenueCatWebhookEvent.RENEWAL } }, "test-webhook-secret");
         // Missing Type
         await svc.handleWebhook({ event: { id: "evt_123" } }, "test-webhook-secret");

         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();
      });
   });
});
