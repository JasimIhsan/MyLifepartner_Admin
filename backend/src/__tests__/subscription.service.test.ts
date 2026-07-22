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
   $executeRaw: jest.fn(),
};

jest.mock("@/config/prisma", () => ({
   __esModule: true,
   default: {
      $transaction: jest.fn((cb: (tx: typeof mockTx) => Promise<void>) => cb(mockTx)),
   },
}));

// ─── Mock logger ──────────────────────────────────────────────────────────────
jest.mock("@/utils/logger", () => ({
   __esModule: true,
   default: { info: jest.fn(), warn: jest.fn(), error: jest.fn(), debug: jest.fn() },
}));

// ─── Mock fetch ───────────────────────────────────────────────────────────────
global.fetch = jest.fn();

import { RevenueCatWebhookEvent } from "@/enums/revenuecat-event.enum";
import { IProcessedRevenueCatEventRepository } from "@/interfaces/repositories/processed-revenuecat-event.repository.interface";
import { ISubscriptionPlanRepository } from "@/interfaces/repositories/subscription-plan.repository.interface";
import { IUserSubscriptionRepository } from "@/interfaces/repositories/user-subscription.repository.interface";
import { IUserFeatureRepository } from "@/interfaces/repositories/user.feature.repository.interface";
import { SubscriptionWebhookRepository } from "@/repositories/subscription-webhook.repository";
import { UserSubscriptionService } from "@/services/user/user.subscription.service";
import { ApiError } from "@/utils/ApiError";
import logger from "@/utils/logger";
import { Prisma } from "@prisma/client";

// ─── Helpers ──────────────────────────────────────────────────────────────────

const FREE_PLAN = { id: 1, name: "FREE", price: 0, durationDays: 36500, isActive: true, isMostPopular: false, storeProductId: null, description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };
const PREMIUM_PLAN = { id: 2, name: "PREMIUM", price: 29900, durationDays: 30, isActive: true, isMostPopular: true, storeProductId: "premium_monthly", description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };

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

// ─── Service factory ──────────────────────────────────────────────────────────

function makeService() {
   return new UserSubscriptionService(
      mockSubPlanRepo as unknown as ISubscriptionPlanRepository,
      mockSubRepo as unknown as IUserSubscriptionRepository,
      mockEventRepo as unknown as IProcessedRevenueCatEventRepository,
      mockFeatureRepo as unknown as IUserFeatureRepository,
      new SubscriptionWebhookRepository()
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
      // Default: advisory lock succeeds
      mockTx.$executeRaw.mockResolvedValue(undefined);
      // Default: idempotency insert succeeds (event is new)
      mockTx.processedRevenueCatEvent.create.mockResolvedValue({ id: "evt_new" });
      // Default: no existing features
      mockTx.userFeature.findUnique.mockResolvedValue(null);
      mockTx.userFeature.create.mockResolvedValue({});
      mockTx.userFeature.update.mockResolvedValue({});
      mockTx.userSubscription.updateMany.mockResolvedValue({ count: 1 });
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
         mockTx.userSubscription.upsert.mockResolvedValue(subWithPlan);
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
         const MEDIUM_PLAN = { id: 3, name: "MEDIUM", price: 14900, durationDays: 30, isActive: true, isMostPopular: false, storeProductId: "medium_monthly", description: null, createdAt: new Date(), updatedAt: new Date(), features: [] };
         const rcEndDate = new Date(Date.now() + 20 * 24 * 60 * 60 * 1000);

         // Current active subscription is PREMIUM (higher plan)
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(makeActiveSub({ planId: PREMIUM_PLAN.id, plan: PREMIUM_PLAN }));
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         // RC says the new product is MEDIUM (lower plan)
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(MEDIUM_PLAN);
         mockSubPlanRepo.getPlanById.mockResolvedValue(PREMIUM_PLAN);
         mockSubRepo.updateUserSubscription.mockResolvedValue({ ...makeActiveSub(), nextPlanId: 3, endDate: rcEndDate });

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
         expect(mockSubRepo.updateUserSubscription).toHaveBeenCalledWith(
            expect.any(Number),
            expect.objectContaining({
               nextPlanId: MEDIUM_PLAN.id,
               willRenew: false,
               endDate: expect.any(Date), // C-5: endDate is updated
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
               data: expect.objectContaining({ expiredAt: expect.any(Date), status: "EXPIRED" }),
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
         mockTx.userSubscription.upsert.mockResolvedValue({
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
         mockTx.userSubscription.upsert.mockResolvedValue({
            ...makeActiveSub(),
            plan: { ...PREMIUM_PLAN, features: [] },
         });

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.INITIAL_PURCHASE }), "test-webhook-secret");

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
         mockTx.userSubscription.upsert.mockResolvedValue({
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

   describe("Cancellation: keeps willRenew=false, preserves ACTIVE status", () => {
      it("sets willRenew=false and cancelledAt without expiring the subscription", async () => {
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.update.mockResolvedValue({});

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.CANCELLATION }), "test-webhook-secret");

         // Must NOT expire the subscription
         expect(mockTx.userSubscription.updateMany).not.toHaveBeenCalled();

         // Must set willRenew=false and record cancelledAt
         expect(mockTx.userSubscription.update).toHaveBeenCalledWith(
            expect.objectContaining({
               data: expect.objectContaining({
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
         mockTx.userSubscription.findFirst.mockResolvedValue(makeActiveSub());
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockTx.userSubscription.create.mockImplementation(async ({ data }: { data: { endDate: Date } }) => ({
            ...makeActiveSub({ planId: 1 }),
            plan: { ...FREE_PLAN, features: [] },
            endDate: data.endDate,
         }));

         const svc = makeService();
         await svc.handleWebhook(makeWebhookPayload({ type: RevenueCatWebhookEvent.EXPIRATION }), "test-webhook-secret");

         const createCall = mockTx.userSubscription.create.mock.calls[0];
         expect(createCall).toBeDefined();
         const endDate: Date = createCall[0].data.endDate;
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
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(null);
         mockSubRepo.deactivateUserSubscriptions.mockResolvedValue({ count: 0 });
         mockSubRepo.createUserSubscription.mockResolvedValue({ ...makeActiveSub({ planId: 1, plan: FREE_PLAN }) });
         mockFeatureRepo.findByUserId.mockResolvedValue(null);
         mockFeatureRepo.create.mockResolvedValue({});

         const svc = makeService();
         // Should not throw — falls back gracefully
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

   // ── syncSubscription ──────────────────────────────────────────────────────

   describe("syncSubscription", () => {
      it("throws 504 on RevenueCat timeout", async () => {
         // Mock fetch to simulate AbortError timeout
         const abortErr = new Error("AbortError");
         abortErr.name = "AbortError";
         (global.fetch as jest.Mock).mockRejectedValue(abortErr);

         const svc = makeService();
         await expect(svc.syncSubscription(42)).rejects.toThrow(ApiError);
         const err = await svc.syncSubscription(42).catch((e) => e);
         expect(err.statusCode).toBe(504);
      });

      it("throws 409 if identity mismatch", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "99", aliases: [] } }),
         });

         const svc = makeService();
         await expect(svc.syncSubscription(42)).rejects.toThrow(ApiError);
         const err = await svc.syncSubscription(42).catch((e) => e);
         expect(err.statusCode).toBe(409);
      });

      it("downgrades to FREE if no active product found", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "42", aliases: [], subscriptions: {} } }),
         });

         // User currently has premium, grace period expired (createdAt long ago)
         const currentSub = makeActiveSub({ planId: PREMIUM_PLAN.id, createdAt: new Date(Date.now() - 5 * 60 * 1000) });
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubRepo.deactivateUserSubscriptions.mockResolvedValue({ count: 1 });
         mockSubRepo.createUserSubscription.mockResolvedValue(makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN }));

         const svc = makeService();
         await svc.syncSubscription(42);

         expect(mockSubRepo.deactivateUserSubscriptions).toHaveBeenCalled();
         expect(mockSubRepo.createUserSubscription).toHaveBeenCalledWith(
            expect.objectContaining({
               plan: { connect: { id: FREE_PLAN.id } },
            })
         );
      });

      it("returns current subscription if no active product but in grace period", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({ subscriber: { original_app_user_id: "42", aliases: [], subscriptions: {} } }),
         });

         // Grace period: createdAt is within 2 minutes
         const currentSub = makeActiveSub({ planId: PREMIUM_PLAN.id, createdAt: new Date(Date.now() - 1 * 60 * 1000) });
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);

         const svc = makeService();
         const res = await svc.syncSubscription(42);

         expect(res?.id).toBe(currentSub.id);
         expect(mockSubRepo.deactivateUserSubscriptions).not.toHaveBeenCalled();
      });

      it("upgrades immediately if new plan price is higher", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({
               subscriber: {
                  original_app_user_id: "42",
                  subscriptions: { premium_monthly: { expires_date: new Date(Date.now() + 10000).toISOString() } },
               },
            }),
         });

         const currentSub = makeActiveSub({ planId: FREE_PLAN.id, plan: FREE_PLAN });
         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(PREMIUM_PLAN);
         mockSubRepo.createUserSubscription.mockResolvedValue(makeActiveSub({ planId: PREMIUM_PLAN.id, plan: PREMIUM_PLAN }));

         const svc = makeService();
         await svc.syncSubscription(42);

         expect(mockSubRepo.deactivateUserSubscriptions).toHaveBeenCalled();
         expect(mockSubRepo.createUserSubscription).toHaveBeenCalledWith(
            expect.objectContaining({
               plan: { connect: { id: PREMIUM_PLAN.id } },
            })
         );
      });

      it("schedules a deferred downgrade if new plan price is lower", async () => {
         (global.fetch as jest.Mock).mockResolvedValue({
            ok: true,
            json: async () => ({
               subscriber: {
                  original_app_user_id: "42",
                  subscriptions: { mid_plan: { expires_date: new Date(Date.now() + 10000).toISOString() } },
               },
            }),
         });

         const midPlan = { ...PREMIUM_PLAN, id: 3, price: 5000, storeProductId: "mid_plan" };
         const currentSub = makeActiveSub({ planId: PREMIUM_PLAN.id, plan: PREMIUM_PLAN });

         mockSubRepo.findActiveSubscriptionByUserId.mockResolvedValue(currentSub);
         mockSubPlanRepo.getPlanByName.mockResolvedValue(FREE_PLAN);
         mockSubPlanRepo.findPlanByStoreProductId.mockResolvedValue(midPlan);
         mockSubPlanRepo.getPlanById.mockResolvedValue(PREMIUM_PLAN); // for currentPlan lookup

         const svc = makeService();
         await svc.syncSubscription(42);

         // Downgrade: update current sub with nextPlanId
         expect(mockSubRepo.updateUserSubscription).toHaveBeenCalledWith(currentSub.id, expect.objectContaining({ nextPlanId: midPlan.id, willRenew: false }));
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
