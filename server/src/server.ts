import { createServer } from "http";
import { Server as IOServer } from "socket.io";
import app from "./app";
import logger from "@utils/logger";
import { connectToDatabase } from "@config/database";
import { initCronJobs } from "@services/cron.service";
import { initSocket } from "@utils/socket";
import dotenv from "dotenv";
import "@my-types/express";

dotenv.config();

const PORT = process.env.PORT || 5000;

const start = async () => {
	try {
		await connectToDatabase();
		initCronJobs();

		const httpServer = createServer(app as any);

		const io = initSocket(httpServer);

		httpServer.listen(PORT, () => {
			logger.info(`Server running on port ${PORT}`);
		});

		exportServerGlobals(io);
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
