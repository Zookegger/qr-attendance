/**
 * Email worker for processing background email jobs.
 *
 * Uses BullMQ Worker to process email sending tasks from the email queue.
 * Handles job execution, error handling, and logging for email delivery.
 */

import { Worker, Job } from "bullmq";
import redis from "@config/redis";
import { EmailJobData } from "@utils/queues/emailQueue";
import logger from "@utils/logger";
import EmailService from "@services/email.service";

/**
 * BullMQ email worker instance.
 *
 * Processes email jobs from the email queue asynchronously.
 * Configured with Redis connection and concurrency settings for
 * efficient background email processing.
 */
const emailWorker = new Worker<EmailJobData>(
	"email",
	async (job: Job<EmailJobData>): Promise<void> => {
		logger.debug(`Processing email job ${job.id} to ${job.data.to}`);

		try {
			await EmailService.sendEmail(job.data);
			logger.debug(`Email sent successfully to ${job.data.to}`);
		} catch (error) {
			logger.error(
				`Email Worker Error: Failed to send email to ${job.data.to}: ${error}`
			);
			throw error;
		}
	},
	{
		connection: redis,
		concurrency: 5,
	}
);

// Event listeners for job completion and failure monitoring
emailWorker.on("completed", (job) => {
	logger.info(`Job ${job.id} completed`);
});

emailWorker.on("failed", (job, err) => {
	logger.info(`Job ${job?.id} failed:`, err);
});

export default emailWorker;
