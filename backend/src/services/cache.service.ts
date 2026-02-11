import redis from "@/config/redis";

class CacheService {
   setCache = async (key: string, value: string, ttl: number = 60 * 60 * 24) => {
      await redis.set(key, value, "EX", ttl);
   };

   getCache = async (key: string) => {
      return await redis.get(key);
   };

   deleteCache = async (key: string) => {
      await redis.del(key);
   };
}

export default new CacheService();
