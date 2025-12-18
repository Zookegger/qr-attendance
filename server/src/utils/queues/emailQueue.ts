import { Queue } from "bullmq";
import redis from "@config/redis";

export const emailQueue = new Queue("email-sending", {
	connection: redis,
});
