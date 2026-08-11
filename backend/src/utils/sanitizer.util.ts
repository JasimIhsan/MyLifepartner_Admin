/**
 * Utility for recursively sanitizing sensitive fields from payloads before saving to the audit log.
 */

const SENSITIVE_KEYS = new Set([
  'password',
  'token',
  'accesstoken',
  'refreshtoken',
  'authorization',
  'cookie',
  'cookies',
  'otp',
  'secret',
  'apikey',
  'cardnumber',
  'cvv',
  'applesignintoken',
  'googlesignintoken',
]);

/**
 * Redacts sensitive fields from objects.
 * Handles nested objects and arrays up to a certain depth to prevent stack overflows.
 */
export const sanitizeForAudit = (obj: any, currentDepth = 0, maxDepth = 5): any => {
  if (currentDepth > maxDepth) {
    return '[TRUNCATED]';
  }

  if (obj === null || obj === undefined) {
    return obj;
  }

  if (typeof obj !== 'object') {
    return obj;
  }

  if (Array.isArray(obj)) {
    return obj.map((item) => sanitizeForAudit(item, currentDepth + 1, maxDepth));
  }

  const sanitized: Record<string, any> = {};

  for (const key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      const lowerKey = key.toLowerCase();
      if (SENSITIVE_KEYS.has(lowerKey) || lowerKey.includes('password') || lowerKey.includes('token') || lowerKey.includes('secret') || lowerKey.includes('key')) {
        sanitized[key] = '[REDACTED]';
      } else {
        sanitized[key] = sanitizeForAudit(obj[key], currentDepth + 1, maxDepth);
      }
    }
  }

  return sanitized;
};
