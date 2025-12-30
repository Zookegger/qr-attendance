import cron from "node-cron";
import { Op } from "sequelize";
import { User, Attendance, RefreshToken } from "@models";
import logger from "@utils/logger";

export const initCronJobs = () => {
	// Run every day at 23:59
	cron.schedule("59 23 * * *", async () => {
		logger.info("Running daily absentee check...");
		try {
			const today = new Date();

			// Get all users
			const users = await User.findAll({ where: { role: "user" } });

			for (const user of users) {
				// Check if attendance exists for today
				const attendance = await Attendance.findOne({
					where: {
						user_id: user.id,
						date: today,
					},
				});

				if (!attendance) {
					// Mark as Absent
					await Attendance.create({
						user_id: user.id,
						date: today,
						status: "Absent",
						check_in_method: null,
						check_out_method: null,
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
	cron.schedule("0 0 * * 0", async () => {
		logger.info("Running weekly token cleanup...");
		try {
			const result = await RefreshToken.destroy({
				where: {
					expires_at: {
						[Op.lt]: new Date(),
					},
				},
			});
			logger.info(`Deleted ${result} expired refresh tokens.`);
		} catch (error) {
			logger.error("Error running weekly token cleanup:", error);
		}
	});
};
