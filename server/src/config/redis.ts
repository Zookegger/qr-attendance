import Redis from "ioredis";
import dotenv from "dotenv";
import logger from "@utils/logger";

dotenv.config();

const redisHost = process.env.REDIS_HOST || "localhost";
const redisPort = parseInt(process.env.REDIS_PORT || "6379", 10);

const redis = new Redis({
	host: redisHost,
	port: redisPort,
	maxRetriesPerRequest: null, // Required for BullMQ
});

redis.on("connect", () => {
	logger.info("Redis connected");
});
redis.on("error", (err) => {
	logger.error("Redis connection error:", err);
});

export default redis;
