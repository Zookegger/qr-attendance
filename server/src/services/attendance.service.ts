import { Attendance, OfficeConfig, Schedule, Workshift, RequestModel, User } from "@models";
import { RequestType } from "@models/request";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth } from "date-fns";
import { AttendanceMethod, AttendanceStatus } from "@models/attendance";
import { CheckInOutDTO } from '@my-types/attendance';
import redis from '@config/redis';
import { getIo } from "@utils/socket";
import { Point } from "@models/officeConfig";
import OfficeService from "./office.service";

// Define a custom error type internally or import a shared one
interface HttpError extends Error {
  status?: number;
}

export default class AttendanceService {
	static async checkIn(dto: CheckInOutDTO) {
		const { userId, code, latitude, longitude, officeId } = dto;

		// 0. Rate limiting by strikes
		const strikesKey = `checkin:strikes:${userId}`;
		const strikesVal = await redis.get(strikesKey);
		const strikes = strikesVal ? parseInt(strikesVal, 10) : 0;
		if (strikes >= 3) {
			const err = new Error('Too many failed check-in attempts') as HttpError;
			err.status = 429;
			throw err;
		}


		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig
		const today = new Date();
		const todayStr = format(today, "yyyy-MM-dd");
		
		// Strictly type the schedule result including nested association
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
				},
			],
		}) as (Schedule & { Shift: Workshift }) | null;

		if (!schedule) {
			const err = new Error("No scheduled shift found for today") as HttpError;
			err.status = 400;
			throw err;
		}

		let officeConfig: OfficeConfig | null = null;
		if (schedule && schedule.Shift && schedule.Shift.officeConfigId) {
			officeConfig = await OfficeConfig.findByPk(schedule.Shift.officeConfigId);
		}

		if (!officeConfig) {
			const err = new Error("Scheduled shift has no assigned office configuration") as HttpError;
			err.status = 400;
			throw err;
		}

		// 1. Verify code exists in Redis for this office
		const officeIdToUse = officeId || officeConfig.id;
		const redisKey = `checkin:office:${officeIdToUse}:code:${code}`;
		const ok = await redis.get(redisKey);
		if (!ok) {
			// increment strikes with sliding TTL (10 minutes)
			await redis.multi().incr(strikesKey).expire(strikesKey, 600).exec();
			const err = new Error('Invalid or expired code') as HttpError;
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

		const distance = OfficeService.calculateDistance(userLocation, officeLocation);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office radius. Distance: ${Math.round(distance)}m`);
		}

		if (officeConfig.geofence && officeConfig.geofence.included && officeConfig.geofence.included.length > 0) {
			const insideGeofence = OfficeService.isPointInGeofence(userLocation, officeConfig.geofence);
			if (!insideGeofence) {
				throw new Error("You are outside the office geofence.");
			}
		}

		// 3. Check if already checked in today
		// Note: 'today' variable is already a Date object
		const existingAttendance = await Attendance.findOne({
			where: {
				userId: userId,
				date: todayStr, // Use todayStr for date matching to be consistent with DATEONLY
			},
		});

		if (existingAttendance && existingAttendance.checkInTime) {
			throw new Error("Already checked in today");
		}

		// 4. Determine Status (Late or Present) using schedule's workshift if available
		let status: AttendanceStatus = AttendanceStatus.PRESENT;
		if (schedule && schedule.Shift) {
			const shift = schedule.Shift;
			// Strict DateTime handling
			const shiftStart = new Date(today);
			shiftStart.setHours(
				shift.startTime.getHours(),
				shift.startTime.getMinutes(),
				shift.startTime.getSeconds(),
				0
			);

			const allowedLate = new Date(shiftStart.getTime() + ((shift.gracePeriod || 0) * 60000));
			
			if (today.getTime() > allowedLate.getTime()) {
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
			date: today, // Sequelize expects string or Date
			scheduleId: schedule ? schedule.id : null,
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
			
			// Emit stats update event for real-time dashboard
			io.emit("stats:update", {
				userId,
				action: "check-in",
				timestamp: new Date(),
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
			const err = new Error('Too many failed check-out attempts') as HttpError;
			err.status = 429;
			throw err;
		}

		// 2. Resolve today's Schedule -> Workshift -> OfficeConfig for check-out validation
		const today = new Date();
		const todayStr = format(today, "yyyy-MM-dd");
		
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
				},
			],
		}) as (Schedule & { Shift: Workshift }) | null;

		if (!schedule) {
			const err = new Error("No scheduled shift found for today") as HttpError;
			err.status = 400;
			throw err;
		}

		let officeConfig: OfficeConfig | null = null;
		if (schedule && schedule.Shift && schedule.Shift.officeConfigId) {
			officeConfig = await OfficeConfig.findByPk(schedule.Shift.officeConfigId);
		}

		if (!officeConfig) {
			const err = new Error("Scheduled shift has no assigned office configuration") as HttpError;
			err.status = 400;
			throw err;
		}

		// Verify code exists in Redis for this office
		const officeIdToUse = officeId || officeConfig.id;
		const redisKey = `checkin:office:${officeIdToUse}:code:${code}`;
		const ok = await redis.get(redisKey);
		if (!ok) {
			await redis.multi().incr(strikesKey).expire(strikesKey, 600).exec();
			const err = new Error('Invalid or expired code') as HttpError;
			err.status = 400;
			throw err;
		}

		// consume code and clear strikes
		await redis.del(redisKey);
		await redis.del(strikesKey);

		const userLocation: Point = { latitude, longitude };
		const officeLocation: Point = { latitude: officeConfig.latitude, longitude: officeConfig.longitude };

		const distance = OfficeService.calculateDistance(userLocation, officeLocation);
		if (distance > officeConfig.radius) {
			throw new Error(`You are outside the office radius. Distance: ${Math.round(distance)}m`);
		}

		if (officeConfig.geofence && officeConfig.geofence.included && officeConfig.geofence.included.length > 0) {
			const insideGeofence = OfficeService.isPointInGeofence(userLocation, officeConfig.geofence);
			if (!insideGeofence) {
				throw new Error("You are outside the office geofence perimeter.");
			}
		}

		// 3. Find Attendance Record
		const attendance = await Attendance.findOne({
			where: {
				userId: userId,
				date: todayStr,
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
		if (schedule) attendance.scheduleId = schedule.id;

		// Early-leave detection: if shift exists and current time is before allowed end
		if (schedule && schedule.Shift) {
			const shift = schedule.Shift;
			// Strict DateTime handling
			const shiftEnd = new Date(today);
			shiftEnd.setHours(
				shift.endTime.getHours(),
				shift.endTime.getMinutes(),
				shift.endTime.getSeconds(),
				0
			);
			
			// consider gracePeriod as minutes allowed for both late arrival and early leave tolerance
			const allowedEarlyThreshold = new Date(shiftEnd.getTime() - ((shift.gracePeriod || 0) * 60000));
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
		
		// Emit socket event for stats update
		try {
			const io = getIo();
			io.emit("stats:update", {
				userId,
				action: "check-out",
				timestamp: new Date(),
			});
		} catch (err) {
			console.error("Socket emit error:", err);
		}
		
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