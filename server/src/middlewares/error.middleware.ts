/**
 * Global error handling middleware for Express application.
 *
 * This middleware catches and processes errors thrown during request processing,
 * logs them appropriately, and sends standardized error responses to clients.
 */

import { NextFunction, Request, Response } from "express";
import { format } from "date-fns";
import logger from "@utils/logger";

/**
 * Express error handling middleware function.
 *
 * Logs the error details and sends a JSON response with error information.
 * This should be the last middleware in the Express app to catch any unhandled errors.
 *
 * @param {any} err - The error object thrown during request processing
 * @param {Request} req - Express request object
 * @param {Response} res - Express response object
 */
export const errorHandler = (
	err: any,
	req: Request,
	res: Response,
	_next: NextFunction
) => {
	logger.error({
		err,
		message: err.message,
		stack: err.stack,
		method: req.method,
		path: req.originalUrl,
		ip: req.ip,
		userAgent: req.headers["user-agent"],
	});

	const time = Date.now();
	const status = err.status || 500;

	const payload: Record<string, any> = {
		message: err.message || "Internal Server Error",
		time: format(time, "dd/MM/yyyy"),
	};

	if (process.env.NODE_ENV !== "production" && err.stack) {
		payload.stack = err.stack;
	}

	res.status(status).json(payload);
};
