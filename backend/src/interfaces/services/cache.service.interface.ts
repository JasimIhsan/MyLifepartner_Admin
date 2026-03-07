export interface ICacheService {
   setCache(key: string, value: string, expiryInSeconds?: number): Promise<void>;
   getCache(key: string): Promise<string | null>;
   deleteCache(key: string): Promise<void>;
   deleteCachePattern(pattern: string): Promise<void>;
}
