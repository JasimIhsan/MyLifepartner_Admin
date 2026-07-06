import redis from "@/config/redis";
import { ICacheService } from "@/interfaces/services/cache.service.interface";

const DEFAULT_CACHE_TTL_SECONDS = 60 * 60 * 24;

export class CacheService implements ICacheService {
   /**
    * Sets cache value.
    *
    * @param key - Cache key.
    * @param value - Cache value.
    * @param ttl - Cache expiry time in seconds.
    * @returns Nothing.
    */
   async setCache(key: string, value: string, ttl: number = DEFAULT_CACHE_TTL_SECONDS): Promise<void> {
      await redis.set(key, value, "EX", ttl);
   }

   /**
    * Gets cache value.
    *
    * @param key - Cache key.
    * @returns Cache value, or null if not found.
    */
   async getCache(key: string): Promise<string | null> {
      return redis.get(key);
   }

   /**
    * Deletes cache value.
    *
    * @param key - Cache key.
    * @returns Nothing.
    */
   async deleteCache(key: string): Promise<void> {
      await redis.del(key);
   }

   /**
    * Deletes cache values by pattern.
    *
    * @param pattern - Cache key pattern.
    * @returns Nothing.
    */
   async deleteCachePattern(pattern: string): Promise<void> {
      const keys = await redis.keys(pattern);

      if (keys.length === 0) {
         return;
      }

      await redis.del(...keys);
   }

   /**
    * Increments cache value.
    *
    * @param key - Cache key.
    * @returns Incremented value.
    */
   async incrCache(key: string): Promise<number> {
      return redis.incr(key);
   }

   /**
    * Sets cache expiry time.
    *
    * @param key - Cache key.
    * @param ttl - Cache expiry time in seconds.
    * @returns Nothing.
    */
   async expireCache(key: string, ttl: number): Promise<void> {
      await redis.expire(key, ttl);
   }
}
