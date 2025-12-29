import { Attendance, OfficeConfig } from "@models";
import { calculateDistance } from "@utils/geo";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth } from "date-fns";

export class AttendanceService {
	static async checkIn(userId: string, qr_code: string, latitude: number, longitude: number) {
		// 1. Validate QR Code (Simple timestamp check for now)
		// Assuming QR code contains a timestamp in milliseconds
		// In a real app, this should be an encrypted token
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			// 30 seconds validity
			throw new Error("Invalid or expired QR code");
		}

		// 2. Validate Location
		const officeConfig = await OfficeConfig.findOne();
		if (!officeConfig) {
			throw new Error("Office configuration not found");
		}

		const distance = calculateDistance(
			latitude,
			longitude,
			officeConfig.latitude,
			officeConfig.longitude
		);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office range. Distance: ${distance}`);
		}

		// 3. Check if already checked in today
		const today = format(new Date(), "yyyy-MM-dd");
		const existingAttendance = await Attendance.findOne({
			where: {
				user_id: userId,
				date: today,
			},
		});

		if (existingAttendance && existingAttendance.check_in_time) {
			throw new Error("Already checked in today");
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
			return existingAttendance;
		} else {
			const attendance = await Attendance.create({
				user_id: userId,
				date: today as any, // Sequelize expects string or Date, but TS might complain if strict
				check_in_time: new Date(),
				check_in_location: { latitude, longitude },
				check_in_method: "QR",
				status: status,
			});
			return attendance;
		}
	}

	static async checkOut(userId: string, qr_code: string, latitude: number, longitude: number) {
		// 1. Validate QR Code
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			throw new Error("Invalid or expired QR code");
		}

		// 2. Validate Location
		const officeConfig = await OfficeConfig.findOne();
		if (!officeConfig) {
			throw new Error("Office configuration not found");
		}

		const distance = calculateDistance(
			latitude,
			longitude,
			officeConfig.latitude,
			officeConfig.longitude
		);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office range. Distance: ${distance}`);
		}

		// 3. Find Attendance Record
		const today = format(new Date(), "yyyy-MM-dd");
		const attendance = await Attendance.findOne({
			where: {
				user_id: userId,
				date: today,
			},
		});

		if (!attendance || !attendance.check_in_time) {
			throw new Error("You have not checked in yet");
		}

		if (attendance.check_out_time) {
			throw new Error("Already checked out today");
		}

		// 4. Update Attendance
		attendance.check_out_time = new Date();
		attendance.check_out_location = { latitude, longitude };
		attendance.check_out_method = "QR";
		await attendance.save();

		return attendance;
	}

	static async getHistory(userId: string, month?: string, year?: string) {
		const whereClause: any = { user_id: userId };

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

		return history;
	}
}