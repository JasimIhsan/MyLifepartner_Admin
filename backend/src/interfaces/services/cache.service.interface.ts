export interface ICacheService {
   setCache(key: string, value: string, expiryInSeconds?: number): Promise<void>;
   getCache(key: string): Promise<string | null>;
   deleteCache(key: string): Promise<void>;
   deleteCachePattern(pattern: string): Promise<void>;
   incrCache(key: string): Promise<number>;
   expireCache(key: string, ttl: number): Promise<void>;
}
