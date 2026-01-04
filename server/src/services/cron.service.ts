import cron from "node-cron";
import { Op } from "sequelize";
import { User, Attendance, RefreshToken } from "@models";
import logger from "@utils/logger";
import { AttendanceMethod, AttendanceStatus } from "@models/attendance";
import { qrCodeQueue } from "@utils/queues/qrCodeQueue";
import { shutdownQrWorker } from "@utils/workers/qrCodeWorker";
import { closeEmailQueue } from "@utils/queues/emailQueue";
import { shutdownEmailWorker } from "@utils/workers/emailWorker";
import { closeRefreshTokenQueue } from "@utils/queues/refreshTokenQueue";
import { shutdownRefreshTokenWorker } from "@utils/workers/refreshTokenWorker";

let scheduledTasks: any[] = [];

const scheduleTask = (expr: string, fn: () => void | Promise<void>) => {
	const task = cron.schedule(expr, fn);
	scheduledTasks.push(task);
	return task;
};

export const initCronJobs = () => {
	// Run every day at 23:59
	scheduleTask("59 23 * * *", async () => {
		logger.info("Running daily absentee check...");
		try {
			const today = new Date();

			// Get all users
			const users = await User.findAll({ where: { role: "user" } });

			for (const user of users) {
				// Check if attendance exists for today
				const attendance = await Attendance.findOne({
					where: {
						userId: user.id,
						date: today,
					},
				});

				if (!attendance) {
					// Mark as Absent
					await Attendance.create({
						userId: user.id,
						date: today,
						status: AttendanceStatus.ABSENT,
						checkInMethod: AttendanceMethod.NONE,
						checkOutMethod: AttendanceMethod.NONE,
					});
					logger.info(
						`Marked user ${user.id} as Absent for ${today}`
					);
				}
			}
			logger.info("Daily absentee check completed.");
		} catch (error) {
			logger.error("Error running daily absentee check:", error);
		}
	});

	// Run every week on Sunday at 00:00
	scheduleTask("0 0 * * 0", async () => {
		logger.info("Running weekly token cleanup...");
		try {
			const result = await RefreshToken.destroy({
				where: {
					expiresAt: {
						[Op.lt]: new Date(),
					},
				},
			});
			logger.info(`Deleted ${result} expired refresh tokens.`);
		} catch (error) {
			logger.error("Error running weekly token cleanup:", error);
		}
	});

	// Schedule QR heartbeat via BullMQ repeatable job (every 30s)

	const startQrHeartbeat = async () => {
		logger.info("Starting QR heartbeat");
		try {
			await qrCodeQueue.add(
				"heartbeat",
				{},
				{
					jobId: "qr:heartbeat",
					repeat: { every: 30000 },
					removeOnComplete: true,
				}
			);
			logger.info("QR heartbeat job scheduled");
		} catch (err) {
			logger.error("Failed to schedule QR heartbeat job:", err);
		}
	};

	const stopQrHeartbeat = async () => {
		logger.info("Stopping QR heartbeat");
		try {
			await qrCodeQueue.removeRepeatable("heartbeat", { every: 30000, jobId: "qr:heartbeat" } as any);
			logger.info("QR heartbeat job removed");
		} catch (err) {
			logger.error("Failed to remove QR heartbeat job:", err);
		}
	};

	// Check on startup if we should be running
	const now = new Date();
	const hour = now.getHours();
	if (hour >= 6 && hour < 22) {
		startQrHeartbeat();
	}

	// Morning: start QR heartbeat every day at 06:00
	scheduleTask("0 6 * * *", async () => {
		logger.info("Starting QR heartbeat (06:00)");
		await startQrHeartbeat();
	});

	// Night: stop QR heartbeat every day at 22:00
	scheduleTask("0 22 * * *", async () => {
		logger.info("Stopping QR heartbeat (22:00)");
		await stopQrHeartbeat();
	});
};

export const shutdownCronJobs = async () => {
	// Stop node-cron tasks
	for (const t of scheduledTasks) {
		try {
			t.stop();
		} catch (err) {
			logger.warn(`Failed to stop cron task: ${err}`);
		}
	}
	scheduledTasks = [];

	// Close QR queue and worker
	try {
		await qrCodeQueue.close();
	} catch (err) {
		logger.warn(`Failed to close QR queue: ${err}`);
	}

	try {
		await shutdownQrWorker();
	} catch (err) {
		logger.warn(`Failed to shutdown QR worker: ${err}`);
	}
	// close email queue and worker
	try {
		await closeEmailQueue();
	} catch (err) {
		logger.warn(`Failed to close email queue: ${err}`);
	}

	try {
		await shutdownEmailWorker();
	} catch (err) {
		logger.warn(`Failed to shutdown email worker: ${err}`);
	}

	// close refresh-token queue and worker
	try {
		await closeRefreshTokenQueue();
	} catch (err) {
		logger.warn(`Failed to close refresh-token queue: ${err}`);
	}

	try {
		await shutdownRefreshTokenWorker();
	} catch (err) {
		logger.warn(`Failed to shutdown refresh-token worker: ${err}`);
	}
};
