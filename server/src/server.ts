import { createServer } from "http";
import { Server as IOServer } from "socket.io";
import app from "./app";
import logger from "@utils/logger";
import { connectToDatabase } from "@config/database";
import { initCronJobs, shutdownCronJobs } from "@services/cron.service";
import { initSocket } from "@utils/socket";
import "@utils/workers/qrCodeWorker"; // initialize QR worker (side-effect)
import dotenv from "dotenv";
import "@my-types/express";

dotenv.config();

const PORT = process.env.PORT || 5000;

let httpServer: any = null;

const start = async () => {
	try {
		await connectToDatabase();
		initCronJobs();

		httpServer = createServer(app as any);

		const io = initSocket(httpServer);

		httpServer.listen(PORT, () => {
			logger.info(`Server running on port ${PORT}`);
		});

		exportServerGlobals(io);

		// graceful shutdown handlers
		process.on("SIGINT", async () => {
			logger.info("SIGINT received, shutting down...");
			try {
				if (httpServer) {
					httpServer.close(() => logger.info("HTTP server closed"));
				}
				await shutdownCronJobs();
				process.exit(0);
			} catch (err) {
				logger.error("Error during shutdown:", err);
				process.exit(1);
			}
		});

		process.on("SIGTERM", async () => {
			logger.info("SIGTERM received, shutting down...");
			try {
				if (httpServer) {
					httpServer.close(() => logger.info("HTTP server closed"));
				}
				await shutdownCronJobs();
				process.exit(0);
			} catch (err) {
				logger.error("Error during shutdown:", err);
				process.exit(1);
			}
		});
	} catch (err) {
		logger.error("Failed to start server:", err);
		process.exit(1);
	}
};

const exportServerGlobals = (io: IOServer): void => {
	// Exporting io on the module for other modules to import if needed
	(module.exports as any).io = io;
};

if (require.main === module) {
	start();
}

export {};
