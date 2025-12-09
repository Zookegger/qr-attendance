import Redis from "ioredis";
import dotenv from "dotenv";

dotenv.config();

const redisHost = process.env.REDIS_HOST || "localhost";
const redisPort = parseInt(process.env.REDIS_PORT || "6379", 10);

const redis = new Redis({
	host: redisHost,
	port: redisPort,
});

redis.on("connect", () => {
	console.log("[INFO] Redis connected");
});

redis.on("error", (err) => {
	console.error("[ERROR] Redis connection error:", err);
});

export default redis;
