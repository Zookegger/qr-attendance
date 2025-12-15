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
