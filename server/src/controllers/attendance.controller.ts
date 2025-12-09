import { Request, Response } from "express";
import { Attendance, OfficeConfig } from "../models";
import { calculateDistance } from "../utils/geo";
import { Op } from "sequelize";

export class AttendanceController {
	// Check In
	static async checkIn(req: Request, res: Response) {
		try {
			const user = req.user!;
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
				officeConfig.longitude,
			);
			if (distance > officeConfig.radius) {
				return res
					.status(400)
					.json({
						message: "You are outside the office range",
						distance,
					});
			}

			// 3. Check if already checked in today
			const today = new Date().toISOString().split("T")[0];
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
			const currentHour = new Date().getHours();
			const currentMinute = new Date().getMinutes();
			const currentTimeString = `${currentHour.toString().padStart(2, "0")}:${currentMinute.toString().padStart(2, "0")}`;

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
					date: today,
					check_in_time: new Date(),
					check_in_location: { latitude, longitude },
					check_in_method: "QR",
					status: status,
				});
				return res.json({ message: "Check-in successful", attendance });
			}
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}

	// Check Out
	static async checkOut(req: Request, res: Response) {
		try {
			const user = req.user!;
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
				officeConfig.longitude,
			);
			if (distance > officeConfig.radius) {
				return res
					.status(400)
					.json({
						message: "You are outside the office range",
						distance,
					});
			}

			// 3. Find Attendance Record
			const today = new Date().toISOString().split("T")[0];
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

			res.json({ message: "Check-out successful", attendance });
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}

	// Get History
	static async getHistory(req: Request, res: Response) {
		try {
			const user = req.user!;
			const { month, year } = req.query;

			const whereClause: any = { user_id: user.id };

			if (month && year) {
				const startDate = new Date(Number(year), Number(month) - 1, 1);
				const endDate = new Date(Number(year), Number(month), 0);
				whereClause.date = {
					[Op.between]: [
						startDate.toISOString().split("T")[0],
						endDate.toISOString().split("T")[0],
					],
				};
			}

			const history = await Attendance.findAll({
				where: whereClause,
				order: [["date", "DESC"]],
			});

			res.json(history);
		} catch (error) {
			res.status(500).json({ message: "Server error", error });
		}
	}
}
