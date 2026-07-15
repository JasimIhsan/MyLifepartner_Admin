import { createCipheriv, randomBytes, randomInt } from "crypto";

enum ZegoTokenErrorCode {
   Success = 0,
   AppIdInvalid = 1,
   UserIdInvalid = 3,
   SecretInvalid = 5,
   EffectiveTimeInvalid = 6,
}

type ZegoTokenInfo = {
   app_id: number;
   user_id: string;
   nonce: number;
   ctime: number;
   expire: number;
   payload: string;
};

class ZegoTokenError extends Error {
   constructor(public readonly errorCode: ZegoTokenErrorCode, message: string) {
      super(message);
      this.name = "ZegoTokenError";
   }
}

const TOKEN_VERSION = "04";
const SECRET_LENGTH = 32;
const IV_LENGTH = 16;
const NONCE_MIN = -2_147_483_648;
const NONCE_MAX = 2_147_483_647;

const AES_ALGORITHMS_BY_KEY_LENGTH: Record<number, string> = {
   16: "aes-128-cbc",
   24: "aes-192-cbc",
   32: "aes-256-cbc",
};

/**
 * Generates a ZEGOCLOUD token.
 *
 * @param appId - ZEGOCLOUD app ID.
 * @param userId - User ID.
 * @param secret - ZEGOCLOUD server secret.
 * @param effectiveTimeInSeconds - Token validity time in seconds.
 * @param payload - Optional token payload.
 * @returns Generated ZEGOCLOUD token.
 */
export function generateToken04(appId: number, userId: string, secret: string, effectiveTimeInSeconds: number, payload: string = ""): string {
   validateTokenInput(appId, userId, secret, effectiveTimeInSeconds);

   const createTime = Math.floor(Date.now() / 1000);

   const tokenInfo: ZegoTokenInfo = {
      app_id: appId,
      user_id: userId,
      nonce: createNonce(),
      ctime: createTime,
      expire: createTime + effectiveTimeInSeconds,
      payload,
   };

   const plainText = JSON.stringify(tokenInfo);
   const iv = createRandomIv();
   const encryptedBuffer = aesEncrypt(plainText, secret, iv);

   return buildToken(tokenInfo.expire, iv, encryptedBuffer);
}

/**
 * Validates token generation input.
 *
 * @param appId - ZEGOCLOUD app ID.
 * @param userId - User ID.
 * @param secret - ZEGOCLOUD server secret.
 * @param effectiveTimeInSeconds - Token validity time in seconds.
 * @returns Nothing.
 */
function validateTokenInput(appId: number, userId: string, secret: string, effectiveTimeInSeconds: number): void {
   if (!Number.isFinite(appId) || appId <= 0) {
      throw createZegoTokenError(ZegoTokenErrorCode.AppIdInvalid, "appId invalid");
   }

   if (!userId.trim()) {
      throw createZegoTokenError(ZegoTokenErrorCode.UserIdInvalid, "userId invalid");
   }

   if (secret.length !== SECRET_LENGTH) {
      throw createZegoTokenError(ZegoTokenErrorCode.SecretInvalid, "secret must be a 32 byte string");
   }

   if (!Number.isFinite(effectiveTimeInSeconds) || effectiveTimeInSeconds <= 0) {
      throw createZegoTokenError(ZegoTokenErrorCode.EffectiveTimeInvalid, "effectiveTimeInSeconds invalid");
   }
}

/**
 * Creates a ZEGOCLOUD token error.
 *
 * @param errorCode - ZEGOCLOUD token error code.
 * @param errorMessage - Error message.
 * @returns ZEGOCLOUD token error.
 */
function createZegoTokenError(errorCode: ZegoTokenErrorCode, errorMessage: string): ZegoTokenError {
   return new ZegoTokenError(errorCode, errorMessage);
}

/**
 * Creates a random nonce.
 *
 * @returns Random nonce.
 */
function createNonce(): number {
   return randomInt(NONCE_MIN, NONCE_MAX);
}

/**
 * Creates a random IV.
 *
 * @returns Random IV.
 */
function createRandomIv(): string {
   return randomBytes(IV_LENGTH).toString("hex").slice(0, IV_LENGTH);
}

/**
 * Gets AES algorithm by key length.
 *
 * @param key - Secret key.
 * @returns AES algorithm name.
 */
function getAesAlgorithm(key: string): string {
   const algorithm = AES_ALGORITHMS_BY_KEY_LENGTH[Buffer.byteLength(key)];

   if (!algorithm) {
      throw new Error(`Invalid key length: ${Buffer.byteLength(key)}`);
   }

   return algorithm;
}

/**
 * Encrypts plain text using AES.
 *
 * @param plainText - Text to encrypt.
 * @param key - Secret key.
 * @param iv - Initialization vector.
 * @returns Encrypted buffer.
 */
function aesEncrypt(plainText: string, key: string, iv: string): Buffer {
   const cipher = createCipheriv(getAesAlgorithm(key), key, iv);

   const encrypted = Buffer.concat([cipher.update(plainText, "utf8"), cipher.final()]);

   return encrypted;
}

/**
 * Builds final ZEGOCLOUD token.
 *
 * @param expireTime - Token expiry timestamp.
 * @param iv - Initialization vector.
 * @param encryptedBuffer - Encrypted token data.
 * @returns Final token string.
 */
function buildToken(expireTime: number, iv: string, encryptedBuffer: Buffer): string {
   const expireBuffer = Buffer.alloc(8);
   expireBuffer.writeBigInt64BE(BigInt(expireTime));

   const ivLengthBuffer = Buffer.alloc(2);
   ivLengthBuffer.writeUInt16BE(Buffer.byteLength(iv));

   const encryptedLengthBuffer = Buffer.alloc(2);
   encryptedLengthBuffer.writeUInt16BE(encryptedBuffer.length);

   const tokenBuffer = Buffer.concat([expireBuffer, ivLengthBuffer, Buffer.from(iv), encryptedLengthBuffer, encryptedBuffer]);

   return `${TOKEN_VERSION}${tokenBuffer.toString("base64")}`;
}
