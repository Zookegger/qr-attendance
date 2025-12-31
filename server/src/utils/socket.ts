import { Server as IOServer } from "socket.io";
import http from "http";
import logger from "./logger";

let io: IOServer | null = null;

export const initSocket = (httpServer: http.Server): IOServer => {
	if (io) return io;

	io = new IOServer(httpServer, {
		cors: { origin: "*", methods: ["GET", "POST"] },
	});

	io.on("connection", (socket) => {
		logger.info(`[Socket] ${socket.id} connected`);

		// Allow clients to join an office room to receive QR updates
		socket.on("join:office", (officeId: string | number) => {
			try {
				socket.join(`office_${officeId}`);
				logger.info(`[Socket] ${socket.id} joined office_${officeId}`);
			} catch (err) {
				logger.warn(`[Socket] Failed to join office room: ${err}`);
			}
		});

		socket.on("disconnect", (reason) => {
			logger.info(`[Socket] ${socket.id} disconnected: ${reason}`);
		});
	});

	return io;
};

export const getIo = (): IOServer => {
	if (!io)
		throw new Error(
			"Socket.io not initialized. Call initSocket(server) first."
		);
	return io;
}
