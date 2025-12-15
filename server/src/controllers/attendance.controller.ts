import { Request, Response } from "express";
import { Attendance, OfficeConfig } from "@models";
import { calculateDistance } from "@utils/geo";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth } from "date-fns";

async function checkIn(req: Request, res: Response) {
	try {
		const user = req.user;

		if (!user) {
			return res
				.status(403)
				.json({ status: 403, message: "Unauthorized" });
		}

		const { qr_code, latitude, longitude } = req.body;

		// 1. Validate QR Code (Simple timestamp check for now)
		// Assuming QR code contains a timestamp in milliseconds
		// In a real app, this should be an encrypted token
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			// 30 seconds validity
			return res
				.status(400)
				.json({ message: "Invalid or expired QR code" });
		}

		// 2. Validate Location
		const officeConfig = await OfficeConfig.findOne();
		if (!officeConfig) {
			return res
				.status(500)
				.json({ message: "Office configuration not found" });
		}

		const distance = calculateDistance(
			latitude,
			longitude,
			officeConfig.latitude,
			officeConfig.longitude
		);
		if (distance > officeConfig.radius) {
			return res.status(400).json({
				message: "You are outside the office range",
				distance,
			});
		}

		// 3. Check if already checked in today
		const today = format(new Date(), "yyyy-MM-dd");
		const existingAttendance = await Attendance.findOne({
			where: {
				user_id: user.id,
				date: today,
			},
		});

		if (existingAttendance && existingAttendance.check_in_time) {
			return res
				.status(400)
				.json({ message: "Already checked in today" });
		}

		// 4. Determine Status (Late or Present)
		const currentTimeString = format(new Date(), "HH:mm");

		let status: "Present" | "Late" = "Present";
		if (currentTimeString > officeConfig.start_hour) {
			status = "Late";
		}

		// 5. Create or Update Attendance
		if (existingAttendance) {
			// If record exists (maybe marked absent by cron or something), update it
			existingAttendance.check_in_time = new Date();
			existingAttendance.check_in_location = { latitude, longitude };
			existingAttendance.check_in_method = "QR";
			existingAttendance.status = status;
			await existingAttendance.save();
			return res.json({
				message: "Check-in successful",
				attendance: existingAttendance,
			});
		} else {
			const attendance = await Attendance.create({
				user_id: user.id,
				date: today as any, // Sequelize expects string or Date, but TS might complain if strict
				check_in_time: new Date(),
				check_in_location: { latitude, longitude },
				check_in_method: "QR",
				status: status,
			});
			return res.json({ message: "Check-in successful", attendance });
		}
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function checkOut(req: Request, res: Response) {
	try {
		const user = req.user;

		if (!user) {
			return res
				.status(403)
				.json({ status: 403, message: "Unauthorized" });
		}

		const { qr_code, latitude, longitude } = req.body;

		// 1. Validate QR Code
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			return res
				.status(400)
				.json({ message: "Invalid or expired QR code" });
		}

		// 2. Validate Location
		const officeConfig = await OfficeConfig.findOne();
		if (!officeConfig) {
			return res
				.status(500)
				.json({ message: "Office configuration not found" });
		}

		const distance = calculateDistance(
			latitude,
			longitude,
			officeConfig.latitude,
			officeConfig.longitude
		);
		if (distance > officeConfig.radius) {
			return res.status(400).json({
				message: "You are outside the office range",
				distance,
			});
		}

		// 3. Find Attendance Record
		const today = format(new Date(), "yyyy-MM-dd");
		const attendance = await Attendance.findOne({
			where: {
				user_id: user.id,
				date: today,
			},
		});

		if (!attendance || !attendance.check_in_time) {
			return res
				.status(400)
				.json({ message: "You have not checked in yet" });
		}

		if (attendance.check_out_time) {
			return res
				.status(400)
				.json({ message: "Already checked out today" });
		}

		// 4. Update Attendance
		attendance.check_out_time = new Date();
		attendance.check_out_location = { latitude, longitude };
		attendance.check_out_method = "QR";
		await attendance.save();

		return res.json({ message: "Check-out successful", attendance });
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

async function getHistory(req: Request, res: Response) {
	try {
		const user = req.user;

		if (!user) {
			return res
				.status(403)
				.json({ status: 403, message: "Unauthorized" });
		}

		const { month, year } = req.query;

		const whereClause: any = { user_id: user.id };

		if (month && year) {
			const reportDate = new Date(Number(year), Number(month) - 1);
			const startDate = startOfMonth(reportDate);
			const endDate = endOfMonth(reportDate);
			whereClause.date = {
				[Op.between]: [
					format(startDate, "yyyy-MM-dd"),
					format(endDate, "yyyy-MM-dd"),
				],
			};
		}

		const history = await Attendance.findAll({
			where: whereClause,
			order: [["date", "DESC"]],
		});

		return res.json(history);
	} catch (error) {
		return res.status(500).json({ message: "Server error", error });
	}
}

export const AttendanceController = {
	checkIn,
	checkOut,
	getHistory,
};
