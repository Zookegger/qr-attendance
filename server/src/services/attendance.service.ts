import { Attendance, OfficeConfig, Schedule, Workshift, RequestModel, User } from "@models";
import { RequestType } from "@models/request";
import { calculateDistance, isPointInPolygon } from "@utils/geo";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { AttendanceMethod, AttendanceStatus } from "@models/attendance";
import { CheckInOutDTO } from '@my-types/attendance';
import redis from '@config/redis';
import { getIo } from "@utils/socket";
import { Point } from "@models/officeConfig";

export default class AttendanceService {
		static async checkIn(dto: CheckInOutDTO) {
			const { userId, code, latitude, longitude, officeId } = dto;

		// 0. Rate limiting by strikes
		const strikesKey = `checkin:strikes:${userId}`;
		const strikesVal = await redis.get(strikesKey);
		const strikes = strikesVal ? parseInt(strikesVal, 10) : 0;
		if (strikes >= 3) {
			const err: any = new Error('Too many failed check-in attempts');
			err.status = 429;
			throw err;
		}


		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig
		const todayStr = format(new Date(), "yyyy-MM-dd");
		const schedule = await Schedule.findOne({
			where: {
				userId: userId,
				startDate: { [Op.lte]: todayStr },
				[Op.or]: [
					{ endDate: null },
					{ endDate: { [Op.gte]: todayStr } },
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

		if (!schedule) {
			const err: any = new Error("No scheduled shift found for today");
			err.status = 400;
			throw err;
		}

		let officeConfig = null as any;
		if (schedule && (schedule as any).Shift && (schedule as any).Shift.officeConfigId) {
			officeConfig = await OfficeConfig.findByPk((schedule as any).Shift.officeConfigId);
		}

		if (!officeConfig) {
			const err: any = new Error("Scheduled shift has no assigned office configuration");
			err.status = 400;
			throw err;
		}

		// 1. Verify code exists in Redis for this office
		const officeIdToUse = officeId || (officeConfig as any).id;
		const redisKey = `checkin:office:${officeIdToUse}:code:${code}`;
		const ok = await redis.get(redisKey);
		if (!ok) {
			// increment strikes with sliding TTL (10 minutes)
			await redis.multi().incr(strikesKey).expire(strikesKey, 600).exec();
			const err: any = new Error('Invalid or expired code');
			err.status = 400;
			throw err;
		}

		// Consume the code to prevent reuse
		await redis.del(redisKey);

		// on success, clear strikes
		await redis.del(strikesKey);

		// Geofence Validation
		const userLocation: Point = { latitude, longitude };
		const officeLocation: Point = { latitude: officeConfig.latitude, longitude: officeConfig.longitude };

		const distance = calculateDistance(userLocation, officeLocation);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office radius. Distance: ${Math.round(distance)}m`);
		}

		if (officeConfig.polygon && Array.isArray(officeConfig.polygon) && officeConfig.polygon.length >= 3) {
			const insidePolygon = isPointInPolygon(userLocation, officeConfig.polygon);
			if (!insidePolygon) {
				throw new Error("You are outside the office polygon perimeter.");
			}
		}

		// 3. Check if already checked in today
		const today = format(new Date(), "yyyy-MM-dd");
		const existingAttendance = await Attendance.findOne({
			where: {
				userId: userId,
				date: today,
			},
		});

		if (existingAttendance && existingAttendance.checkInTime) {
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
			userId: userId,
			date: today as any, // Sequelize expects string or Date, but TS might complain if strict
			scheduleId: schedule ? (schedule as any).id : null,
			checkInTime: new Date(),
			checkInLocation: { latitude, longitude },
			checkInMethod: AttendanceMethod.QR,
			status: status,
		});

		// Emit socket event for kiosk feedback
		try {
			const user = await User.findByPk(userId);
			const userName = user ? user.name : "Unknown User";
			const io = getIo();
			io.to(`office_${officeIdToUse}`).emit("attendance:log", {
				userName,
				action: "Check In",
				time: new Date(),
			});
		} catch (err) {
			console.error("Socket emit error:", err);
		}

		return attendance;
	}

	static async checkOut(dto: CheckInOutDTO) {
		const { userId, code, latitude, longitude, officeId } = dto;

		// Rate limiting
		const strikesKey = `checkin:strikes:${userId}`;
		const strikesVal = await redis.get(strikesKey);
		const strikes = strikesVal ? parseInt(strikesVal, 10) : 0;
		if (strikes >= 3) {
			const err: any = new Error('Too many failed check-out attempts');
			err.status = 429;
			throw err;
		}

		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig for check-out validation
		const todayStr = format(new Date(), "yyyy-MM-dd");
		const schedule = await Schedule.findOne({
			where: {
				userId: userId,
				startDate: { [Op.lte]: todayStr },
				[Op.or]: [
					{ endDate: null },
					{ endDate: { [Op.gte]: todayStr } },
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

		if (!schedule) {
			const err: any = new Error("No scheduled shift found for today");
			err.status = 400;
			throw err;
		}

		let officeConfig = null as any;
		if (schedule && (schedule as any).Shift && (schedule as any).Shift.officeConfigId) {
			officeConfig = await OfficeConfig.findByPk((schedule as any).Shift.officeConfigId);
		}

		if (!officeConfig) {
			const err: any = new Error("Scheduled shift has no assigned office configuration");
			err.status = 400;
			throw err;
		}

		// Verify code exists in Redis for this office
		const officeIdToUse = officeId || (officeConfig as any).id;
		const redisKey = `checkin:office:${officeIdToUse}:code:${code}`;
		const ok = await redis.get(redisKey);
		if (!ok) {
			await redis.multi().incr(strikesKey).expire(strikesKey, 600).exec();
			const err: any = new Error('Invalid or expired code');
			err.status = 400;
			throw err;
		}

		// consume code and clear strikes
		await redis.del(redisKey);
		await redis.del(strikesKey);

		const userLocation: Point = { latitude, longitude };
		const officeLocation: Point = { latitude: officeConfig.latitude, longitude: officeConfig.longitude };

		const distance = calculateDistance(userLocation, officeLocation);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office radius. Distance: ${Math.round(distance)}m`);
		}

		if (officeConfig.polygon && Array.isArray(officeConfig.polygon) && officeConfig.polygon.length >= 3) {
			const insidePolygon = isPointInPolygon(userLocation, officeConfig.polygon);
			if (!insidePolygon) {
				throw new Error("You are outside the office polygon perimeter.");
			}
		}

		// 3. Find Attendance Record
		const today = format(new Date(), "yyyy-MM-dd");
		const attendance = await Attendance.findOne({
			where: {
				userId: userId,
				date: today,
			},
		});

		if (!attendance || !attendance.checkInTime) {
			throw new Error("You have not checked in yet");
		}

		if (attendance.checkOutTime) {
			throw new Error("Already checked out today");
		}

		// 4. Update Attendance & detect early leave
		const nowDate = new Date();
		attendance.checkOutTime = nowDate;
		attendance.checkOutLocation = { latitude, longitude };
		attendance.checkOutMethod = AttendanceMethod.QR;

		// Attach schedule_id if we resolved one earlier (useful for reports)
		if (schedule) attendance.scheduleId = (schedule as any).id;

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
					userId: userId,
					type: RequestType.LATE_EARLY,
					fromDate: nowDate,
					reason,
				});
				attendance.requestId = req.id;
			}
		}

		await attendance.save();
		return attendance;
	}

	static async getHistory(userId: string, month?: string, year?: string) {
		const whereClause: any = { userId: userId };

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