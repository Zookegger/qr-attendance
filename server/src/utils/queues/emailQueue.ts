/**
 * Email queue configuration using BullMQ.
 *
 * Defines the email job queue for background processing of email sending tasks.
 * Configured with Redis connection and retry policies for reliable email delivery.
 */

import { Queue } from "bullmq";
import redis from "@config/redis";

/**
 * Data structure for email job data.
 *
 * Defines the payload structure for email jobs processed by the queue.
 * Contains all necessary information to send an email through the SMTP service.
 */
export interface EmailJobData {
	/** Recipient email address */
	to: string;
	/** Email subject line */
	subject: string;
	/** HTML content of the email */
	html: string;
	/** Optional plain text version of the email */
	text?: string;
}

/**
 * BullMQ email queue instance.
 *
 * Configured queue for processing email sending jobs asynchronously.
 * Uses Redis as the backing store and includes retry logic and cleanup policies.
 */
export const emailQueue = new Queue<EmailJobData>("email", {
	connection: redis,

	// Default job settings for all email jobs
	defaultJobOptions: {
		// Retry a job up to 3 times if it fails (e.g., SMTP error, timeout, etc.)
		attempts: 3,

		// Wait strategy for retries
		backoff: {
			type: "exponential", // delay increases exponentially
			delay: 2000, // first retry after 2s, then 4s, then 8s, etc.
		},

		// Auto-cleanup successful jobs
		removeOnComplete: {
			count: 100, // keep at most the last 100 successful jobs
			age: 24 * 3600, // or remove if older than 24 hours (in seconds)
		},

		// Auto-cleanup failed jobs
		removeOnFail: {
			count: 1000, // keep at most 1000 failed jobs, delete older ones
		},
	},
});
