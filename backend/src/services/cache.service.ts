import redis from "@/config/redis";
import { ICacheService } from "../interfaces/services/cache.service.interface";

export class CacheService implements ICacheService {
   setCache = async (key: string, value: string, ttl: number = 60 * 60 * 24) => {
      await redis.set(key, value, "EX", ttl);
   };

   getCache = async (key: string) => {
      return await redis.get(key);
   };

   deleteCache = async (key: string) => {
      await redis.del(key);
   };

   deleteCachePattern = async (pattern: string) => {
      const keys = await redis.keys(pattern);
      if (keys.length > 0) {
         await redis.del(...keys);
      }
   };

   incrCache = async (key: string): Promise<number> => {
      return await redis.incr(key);
   };

   expireCache = async (key: string, ttl: number): Promise<void> => {
      await redis.expire(key, ttl);
   };
}
