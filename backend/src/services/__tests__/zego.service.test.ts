/**
 * Unit tests for backend ZegoService — generateToken() & renewToken().
 *
 * Platform coverage note:
 *   The token produced by this service is consumed identically by:
 *     • iOS     → ZIMLoginConfig.token  (Swift/ObjC ZIM SDK)
 *     • Android → ZIMLoginConfig.token  (Kotlin/Java ZIM SDK)
 *     • Web     → ZIMLoginConfig.token  (JS ZIM SDK via index.js)
 *   All three SDKs accept the same Token04 format, so verifying the backend
 *   output covers all three platforms without needing a device.
 *
 * What is tested:
 *   ✔ Token starts with version prefix "04" (Token04 spec)
 *   ✔ Base64 payload is non-empty and well-formed
 *   ✔ Expiry is embedded ≈ 3 hours in the future
 *   ✔ Every call produces a unique token (random nonce)
 *   ✔ Tokens differ across different userIds
 *   ✔ renewToken() matches generateToken() format and expiry
 *   ✔ assertConfigured() throws ApiError(500) when appId = 0
 *   ✔ assertConfigured() throws ApiError(500) when serverSecret is empty
 *   ✔ generateToken04 rejects empty/whitespace userId
 *   ✔ generateToken04 rejects invalid effectiveTime
 *   ✔ generateToken04 rejects short secret
 *   ✔ generateToken04 rejects appId <= 0
 */

import { ZegoService } from "@/services/zego.service";
import { ApiError } from "@/utils/ApiError";
import { generateToken04 } from "@/utils/zegoServerAssistant";

// ─── Constants ────────────────────────────────────────────────────────────────

/** 32-byte ASCII string — satisfies AES-256 key length requirement. */
const VALID_SECRET = "a".repeat(32);
const VALID_APP_ID = 1331651742;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Construct a ZegoService and inject the given appId / serverSecret directly
 * into the private fields so tests are completely independent of the .env file.
 */
function buildService(appId: number, secret: string): ZegoService {
  const svc = new ZegoService();
  (svc as unknown as Record<string, unknown>)["appId"] = appId;
  (svc as unknown as Record<string, unknown>)["serverSecret"] = secret;
  return svc;
}

/**
 * Read the 8-byte BigInt64BE expiry value that Token04 embeds at position 0
 * of the decoded base64 payload (after stripping the 2-char "04" version tag).
 */
function readTokenExpiry(token: string): number {
  const buf = Buffer.from(token.slice(2), "base64");
  return Number(buf.readBigInt64BE(0));
}

// ─── Suite ────────────────────────────────────────────────────────────────────

describe("ZegoService — backend unit tests (covers iOS / Android / Web)", () => {
  let service: ZegoService;

  beforeEach(() => {
    service = buildService(VALID_APP_ID, VALID_SECRET);
  });

  // ── generateToken ────────────────────────────────────────────────────────────

  describe("generateToken(userId)", () => {
    it('returns a string starting with the Token04 version prefix "04"', () => {
      expect(service.generateToken("1")).toMatch(/^04/);
    });

    it("returns a non-empty base64 payload after the version prefix", () => {
      const payload = service.generateToken("1").slice(2);
      expect(payload.length).toBeGreaterThan(0);
      expect(payload).toMatch(/^[A-Za-z0-9+/=]+$/);
    });

    it("embeds expiry ≈ 3 hours from now (±5 s tolerance)", () => {
      const before = Math.floor(Date.now() / 1000);
      const token = service.generateToken("1");
      const after = Math.floor(Date.now() / 1000);
      const THREE_H = 3 * 60 * 60;

      const expiry = readTokenExpiry(token);
      expect(expiry).toBeGreaterThanOrEqual(before + THREE_H);
      expect(expiry).toBeLessThanOrEqual(after + THREE_H + 5);
    });

    it("generates a unique token on every call (random nonce)", () => {
      const t1 = service.generateToken("1");
      const t2 = service.generateToken("1");
      expect(t1).not.toBe(t2);
    });

    it("generates different tokens for different userIds", () => {
      const tA = service.generateToken("10");
      const tB = service.generateToken("20");
      expect(tA).not.toBe(tB);
    });

    it("works with any non-empty string userId (iOS / Android / Web users have numeric IDs)", () => {
      expect(() => service.generateToken("999999")).not.toThrow();
    });
  });

  // ── renewToken ───────────────────────────────────────────────────────────────

  describe("renewToken(userId)", () => {
    it('returns a string starting with "04" — same format as generateToken', () => {
      expect(service.renewToken("1")).toMatch(/^04/);
    });

    it("embeds expiry ≈ 3 hours from now — renewed tokens get a full fresh window", () => {
      const before = Math.floor(Date.now() / 1000);
      const token = service.renewToken("1");
      const after = Math.floor(Date.now() / 1000);
      const THREE_H = 3 * 60 * 60;

      const expiry = readTokenExpiry(token);
      expect(expiry).toBeGreaterThanOrEqual(before + THREE_H);
      expect(expiry).toBeLessThanOrEqual(after + THREE_H + 5);
    });

    it("produces a different token than generateToken (new nonce each time)", () => {
      const original = service.generateToken("1");
      const renewed = service.renewToken("1");
      expect(renewed).not.toBe(original);
    });

    it("is unique on consecutive renewals — prevents token replay attacks", () => {
      const r1 = service.renewToken("1");
      const r2 = service.renewToken("1");
      expect(r1).not.toBe(r2);
    });
  });

  // ── assertConfigured guard ───────────────────────────────────────────────────

  describe("assertConfigured() — triggered by both generateToken and renewToken", () => {
    it("generateToken throws ApiError(500) when appId is 0 (misconfigured env)", () => {
      const bad = buildService(0, VALID_SECRET);
      expect(() => bad.generateToken("1")).toThrow(ApiError);
      try {
        bad.generateToken("1");
      } catch (e) {
        expect((e as ApiError).statusCode).toBe(500);
        expect((e as ApiError).message).toMatch(/ZEGOCLOUD/);
      }
    });

    it("generateToken throws ApiError(500) when serverSecret is empty", () => {
      const bad = buildService(VALID_APP_ID, "");
      expect(() => bad.generateToken("1")).toThrow(ApiError);
      try {
        bad.generateToken("1");
      } catch (e) {
        expect((e as ApiError).statusCode).toBe(500);
      }
    });

    it("renewToken throws ApiError(500) when appId is 0", () => {
      const bad = buildService(0, VALID_SECRET);
      expect(() => bad.renewToken("1")).toThrow(ApiError);
    });

    it("renewToken throws ApiError(500) when serverSecret is empty", () => {
      const bad = buildService(VALID_APP_ID, "");
      expect(() => bad.renewToken("1")).toThrow(ApiError);
    });
  });

  // ── generateToken04 input validation ─────────────────────────────────────────

  describe("generateToken04() — low-level validation (shared by all platforms)", () => {
    it("throws when userId is an empty string", () => {
      expect(() => generateToken04(VALID_APP_ID, "", VALID_SECRET, 10800)).toThrow();
    });

    it("throws when userId is whitespace only", () => {
      expect(() => generateToken04(VALID_APP_ID, "   ", VALID_SECRET, 10800)).toThrow();
    });

    it("throws when effectiveTimeInSeconds is zero", () => {
      expect(() => generateToken04(VALID_APP_ID, "1", VALID_SECRET, 0)).toThrow();
    });

    it("throws when effectiveTimeInSeconds is negative", () => {
      expect(() => generateToken04(VALID_APP_ID, "1", VALID_SECRET, -60)).toThrow();
    });

    it("throws when secret is shorter than 32 bytes (AES key constraint)", () => {
      expect(() => generateToken04(VALID_APP_ID, "1", "tooshort", 10800)).toThrow();
    });

    it("throws when appId is zero", () => {
      expect(() => generateToken04(0, "1", VALID_SECRET, 10800)).toThrow();
    });

    it("throws when appId is negative", () => {
      expect(() => generateToken04(-1, "1", VALID_SECRET, 10800)).toThrow();
    });

    it("succeeds with a 3-hour validity window (the real production value)", () => {
      expect(() =>
        generateToken04(VALID_APP_ID, "1", VALID_SECRET, 10800)
      ).not.toThrow();
    });
  });
});
