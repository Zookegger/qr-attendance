import { Queue } from "bullmq";
import redis from "@config/redis";

export const refreshTokenQueue = new Queue("refresh-tokens", {
	connection: redis,
	defaultJobOptions: {
		removeOnComplete: true,
		removeOnFail: false,
	},
});

export const closeRefreshTokenQueue = async () => {
  try {
    await refreshTokenQueue.close();
  } catch (err) {
    // ignore
  }
};

export const addRefreshTokenJob = async (opts?: { once?: boolean }) => {
	if (opts?.once) {
		await refreshTokenQueue.add("refresh-token-cleanup", {}, { delay: 0 });
		return;
	}

	await refreshTokenQueue.add(
		"refresh-token-cleanup",
		{},
		{ repeat: { pattern: "0 3 * * *" } }
	);
};
