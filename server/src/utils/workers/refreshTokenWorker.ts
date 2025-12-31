import redis from "@config/redis";
import { RefreshToken } from "@models";
import logger from "@utils/logger";
import { Job, Worker } from "bullmq";
import { Op } from "sequelize";

const refreshTokenWorker = new Worker(
	"refresh-tokens",
	async (job: Job) => {
		logger.info(
			`refresh-token-worker processing job ${job.id} (${job.name})`
		);
		if (job.name !== "refresh-token-cleanup") {
			logger.warn("Unknown job name:", job.name);
			return;
		}

		// 1) delete expired tokens
		const now = new Date();
		const expiredDeleted = await RefreshToken.destroy({
			where: { expires_at: { [Op.lt]: now } },
		});

		// 2) optionally cleanup revoked tokens older than 7 days
		const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
		const revokedDeleted = await RefreshToken.destroy({
			where: {
				revoked: true,
				updated_at: { [Op.lt]: cutoff },
			},
		});

		logger.info(
			`cleanup: expired=${expiredDeleted} revokedOlderThan7d=${revokedDeleted}`
		);
	},
	{ connection: redis }
);

refreshTokenWorker.on("completed", (job) => {
	logger.debug(`Job ${job.id} has completed!`);
});

refreshTokenWorker.on("failed", (job, err) => {
	logger.error(`Job ${job?.id} failed: ${err.message}`);
});

export default refreshTokenWorker;

export const shutdownRefreshTokenWorker = async () => {
	try {
		await refreshTokenWorker.close();
		logger.info("RefreshToken worker closed");
	} catch (err) {
		logger.warn(`RefreshToken worker close error: ${err}`);
	}
};