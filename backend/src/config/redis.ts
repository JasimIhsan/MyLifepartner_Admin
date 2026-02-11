import Redis from "ioredis";
import logger from "../utils/logger";
import env from "./env";

const redis = new Redis(env.REDIS_URL);

redis.on("connect", () => {
   logger.info("Redis connected successfully");
});

redis.on("error", (err) => {
   logger.error("Redis connection error:", err);
});

export default redis;
