import { NextFunction, Request, Response } from "express";
import { AttendanceService } from "@services/attendance.service";
import { validationResult } from "express-validator";

const checkIn = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const user = req.user;

	if (!user) {
		return res
			.status(403)
			.json({ status: 403, message: "Unauthorized" });
	}

	const { qr_code, latitude, longitude } = req.body;

	try {
		const attendance = await AttendanceService.checkIn(user.id, qr_code, latitude, longitude);

		return res.json({ message: "Check-in successful", attendance });
	} catch (error) {
		return next(error);
	}
};

const checkOut = async (req: Request, res: Response, next: NextFunction) => {
	const errors = validationResult(req);
	if (!errors.isEmpty()) {
		return res.status(400).json({ errors: errors.array() });
	}

	const user = req.user;

	if (!user) {
		return res
			.status(403)
			.json({ status: 403, message: "Unauthorized" });
	}

	const { qr_code, latitude, longitude } = req.body;

	try {
		const attendance = await AttendanceService.checkOut(user.id, qr_code, latitude, longitude);

		return res.json({ message: "Check-out successful", attendance });
	} catch (error) {
		return next(error);
	}
};

const getHistory = async (req: Request, res: Response, next: NextFunction) => {
	try {
		const user = req.user;

		if (!user) {
			return res
				.status(403)
				.json({ status: 403, message: "Unauthorized" });
		}

		const { month, year } = req.query;

		const history = await AttendanceService.getHistory(user.id, month as string, year as string);

		return res.json(history);
	} catch (error) {
		return next(error);
	}
};

export const AttendanceController = {
	checkIn,
	checkOut,
	getHistory,
};
