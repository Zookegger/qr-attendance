import { Attendance, OfficeConfig, Schedule, Workshift, RequestModel } from "@models";
import { RequestType } from "@models/request";
import { calculateDistance } from "@utils/geo";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { AttendanceMethod, AttendanceStatus } from "@models/attendance";
import { CheckInOutDTO } from '@my-types/attendance';

export default class AttendanceService {
	static async checkIn(dto: CheckInOutDTO) {
		const { user_id: userId, qr_code, latitude, longitude } = dto;
		// 1. Validate QR Code (Simple timestamp check for now)
		// Assuming QR code contains a timestamp in milliseconds
		// In a real app, this should be an encrypted token
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			// 30 seconds validity
			throw new Error("Invalid or expired QR code");
		}


		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig
		const todayStr = format(new Date(), "yyyy-MM-dd");
		const schedule = await Schedule.findOne({
			where: {
				user_id: userId,
				start_date: { [Op.lte]: todayStr },
				[Op.or]: [
					{ end_date: null },
					{ end_date: { [Op.gte]: todayStr } },
				],
			},
			include: [
				{
					model: Workshift,
					as: "Shift",
					include: [],
				},
			],
		});

		let officeConfig = null as any;
		if (schedule && (schedule as any).Shift && (schedule as any).Shift.office_config_id) {
			officeConfig = await OfficeConfig.findByPk((schedule as any).Shift.office_config_id);
		} else {
			officeConfig = await OfficeConfig.findOne();
		}

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

		// 4. Determine Status (Late or Present) using schedule's workshift if available
		let status: AttendanceStatus = AttendanceStatus.PRESENT;
		if (schedule && (schedule as any).Shift) {
			const shift = (schedule as any).Shift as any;
			// shift.startTime is stored as TIME; treat as HH:mm:ss or HH:mm
			const shiftTime = shift.startTime as string;
			const [h, m] = shiftTime.split(":").map((s: string) => parseInt(s, 10));
			const shiftStart = new Date();
			shiftStart.setHours(h || 0, m || 0, 0, 0);
			const allowedLate = new Date(shiftStart.getTime() + (shift.gracePeriod || 0) * 60000);
			if (Date.now() > allowedLate.getTime()) {
				status = AttendanceStatus.LATE;
			}
		}

		// 5. Create Attendance
		// If an attendance record already exists for today, do not silently overwrite it.
		// Users should submit a correction/request if an existing record was created by a background job.
		if (existingAttendance) {
			throw new Error("Attendance record already exists for today. If this is incorrect, please submit a correction request.");
		}

		const attendance = await Attendance.create({
			user_id: userId,
			date: today as any, // Sequelize expects string or Date, but TS might complain if strict
			schedule_id: schedule ? (schedule as any).id : null,
			check_in_time: new Date(),
			check_in_location: { latitude, longitude },
			check_in_method: AttendanceMethod.QR,
			status: status,
		});
		return attendance;
	}

	static async checkOut(dto: CheckInOutDTO) {
		const { user_id: userId, qr_code, latitude, longitude } = dto;
		// 1. Validate QR Code
		const qrTimestamp = parseInt(qr_code);
		const now = Date.now();
		if (isNaN(qrTimestamp) || now - qrTimestamp > 30000) {
			throw new Error("Invalid or expired QR code");
		}

		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig for check-out validation
		const todayStr = format(new Date(), "yyyy-MM-dd");
		const schedule = await Schedule.findOne({
			where: {
				user_id: userId,
				start_date: { [Op.lte]: todayStr },
				[Op.or]: [
					{ end_date: null },
					{ end_date: { [Op.gte]: todayStr } },
				],
			},
			include: [
				{
					model: Workshift,
					as: "Shift",
					include: [],
				},
			],
		});

		let officeConfig = null as any;
		if (schedule && (schedule as any).Shift && (schedule as any).Shift.office_config_id) {
			officeConfig = await OfficeConfig.findByPk((schedule as any).Shift.office_config_id);
		} else {
			officeConfig = await OfficeConfig.findOne();
		}

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

		// 4. Update Attendance & detect early leave
		const nowDate = new Date();
		attendance.check_out_time = nowDate;
		attendance.check_out_location = { latitude, longitude };
		attendance.check_out_method = AttendanceMethod.QR;

		// Attach schedule_id if we resolved one earlier (useful for reports)
		if (schedule) attendance.schedule_id = (schedule as any).id;

		// Early-leave detection: if shift exists and current time is before allowed end
		if (schedule && (schedule as any).Shift) {
			const shift = (schedule as any).Shift as any;
			const shiftEndTime = shift.endTime as string; // TIME field
			const [eh, em] = shiftEndTime.split(":").map((s: string) => parseInt(s, 10));
			const shiftEnd = new Date();
			shiftEnd.setHours(eh || 0, em || 0, 0, 0);
			// consider gracePeriod as minutes allowed for both late arrival and early leave tolerance
			const allowedEarlyThreshold = new Date(shiftEnd.getTime() - (shift.gracePeriod || 0) * 60000);
			if (nowDate.getTime() < allowedEarlyThreshold.getTime()) {
				// create a request record for early leave
				const reason = `Auto-generated early-leave detected at ${nowDate.toISOString()}`;
				const req = await RequestModel.create({
					user_id: userId,
					type: RequestType.LATE_EARLY,
					from_date: nowDate,
					reason,
				});
				attendance.request_id = req.id;
			}
		}

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