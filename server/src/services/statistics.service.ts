import { Attendance, User, Schedule, Workshift } from "@models";
import { AttendanceStatus } from "@models/attendance";
import { Op } from "sequelize";
import { format, startOfMonth, endOfMonth, differenceInMinutes } from "date-fns";

interface PersonalStats {
	checkInTime: string | null;
	checkOutTime: string | null;
	totalTime: string;
	isCheckedIn: boolean;
	daysWorked: number;
	daysOff: number;
	overtimeHours: string;
	lateArrivals: number;
}

interface TeamStats {
	teamPresent: number;
	teamLate: number;
	teamAbsent: number;
	total: number;
}

interface TodayShift {
	checkInTime: string | null;
	checkOutTime: string | null;
	totalTime: string;
	isCheckedIn: boolean;
	status: AttendanceStatus | null;
}

export default class StatisticsService {
	/**
	 * Get current shift status for today
	 */
	static async getTodayShift(userId: string): Promise<TodayShift> {
		const today = format(new Date(), "yyyy-MM-dd");
		
		const attendance = await Attendance.findOne({
			where: {
				userId,
				date: today,
			},
		});

		if (!attendance) {
			return {
				checkInTime: null,
				checkOutTime: null,
				totalTime: "--:--",
				isCheckedIn: false,
				status: null,
			};
		}

		const checkInTime = attendance.checkInTime
			? format(attendance.checkInTime, "HH:mm")
			: null;
		const checkOutTime = attendance.checkOutTime
			? format(attendance.checkOutTime, "HH:mm")
			: null;
		const isCheckedIn = !!attendance.checkInTime && !attendance.checkOutTime;

		let totalTime = "--:--";
		if (attendance.checkInTime) {
			const endTime = attendance.checkOutTime || new Date();
			const minutes = differenceInMinutes(endTime, attendance.checkInTime);
			const hours = Math.floor(minutes / 60);
			const mins = minutes % 60;
			totalTime = `${hours}h ${mins}m`;
		}

		return {
			checkInTime,
			checkOutTime,
			totalTime,
			isCheckedIn,
			status: attendance.status,
		};
	}

	/**
	 * Get personal monthly statistics
	 */
	static async getPersonalStats(userId: string, month?: number, year?: number): Promise<PersonalStats> {
		const now = new Date();
		const targetMonth = month || now.getMonth() + 1;
		const targetYear = year || now.getFullYear();

		const startDate = startOfMonth(new Date(targetYear, targetMonth - 1, 1));
		const endDate = endOfMonth(startDate);

		// Get today's shift
		const todayShift = await this.getTodayShift(userId);

		// Get all attendance records for the month
		const attendances = await Attendance.findAll({
			where: {
				userId,
				date: {
					[Op.between]: [format(startDate, "yyyy-MM-dd"), format(endDate, "yyyy-MM-dd")],
				},
			},
			include: [
				{
					model: Schedule,
					as: "schedule",
					include: [
						{
							model: Workshift,
							as: "Shift",
						},
					],
				},
			],
		});

		// Calculate statistics
		let daysWorked = 0;
		let daysOff = 0;
		let lateArrivals = 0;
		let totalOvertimeMinutes = 0;

		attendances.forEach((att) => {
			if (att.status === AttendanceStatus.PRESENT || att.status === AttendanceStatus.LATE) {
				daysWorked++;
			}
			if (att.status === AttendanceStatus.LATE) {
				lateArrivals++;
			}
			if (att.status === AttendanceStatus.ABSENT) {
				daysOff++;
			}

			// Calculate overtime
			if (att.checkInTime && att.checkOutTime && att.schedule?.Shift) {
				const shift = att.schedule.Shift;
				const checkOutTime = att.checkOutTime;
				
				// Parse shift end time (assuming it's a TIME field)
				const shiftEndStr = shift.endTime.toString();
				const timeParts = shiftEndStr.split(':').map(Number);
				const endHour = timeParts[0];
				const endMinute = timeParts[1];
				
				if (endHour !== undefined && endMinute !== undefined) {
					const shiftEndDate = new Date(att.date);
					shiftEndDate.setHours(endHour, endMinute, 0, 0);

					// If checked out after shift end time, count as overtime
					if (checkOutTime > shiftEndDate) {
						const overtimeMinutes = differenceInMinutes(checkOutTime, shiftEndDate);
						if (overtimeMinutes > 0) {
							totalOvertimeMinutes += overtimeMinutes;
						}
					}
				}
			}
		});

		const overtimeHours = totalOvertimeMinutes > 0
			? `${Math.floor(totalOvertimeMinutes / 60)}h`
			: "0h";

		return {
			checkInTime: todayShift.checkInTime,
			checkOutTime: todayShift.checkOutTime,
			totalTime: todayShift.totalTime,
			isCheckedIn: todayShift.isCheckedIn,
			daysWorked,
			daysOff,
			overtimeHours,
			lateArrivals,
		};
	}

	/**
	 * Get team statistics for today (for managers/admins)
	 */
	static async getTeamStats(): Promise<TeamStats> {
		const today = format(new Date(), "yyyy-MM-dd");

		// Get all active users
		const activeUsers = await User.count({
			where: {
				status: "ACTIVE",
			},
		});

		// Get today's attendance records
		const attendances = await Attendance.findAll({
			where: {
				date: today,
			},
		});

		// Count by status
		let teamPresent = 0;
		let teamLate = 0;
		let teamAbsent = 0;

		attendances.forEach((att) => {
			if (att.status === AttendanceStatus.PRESENT) {
				teamPresent++;
			} else if (att.status === AttendanceStatus.LATE) {
				teamLate++;
			} else if (att.status === AttendanceStatus.ABSENT) {
				teamAbsent++;
			}
		});

		return {
			teamPresent,
			teamLate,
			teamAbsent,
			total: activeUsers,
		};
	}

	/**
	 * Get detailed team attendance for today (for realtime dashboard)
	 */
	static async getTeamAttendanceDetails() {
		const today = format(new Date(), "yyyy-MM-dd");

		const attendances = await Attendance.findAll({
			where: {
				date: today,
			},
			include: [
				{
					model: User,
					as: "user",
					attributes: ["id", "name", "email", "position", "department"],
				},
			],
			order: [["checkInTime", "DESC"]],
		});

		return attendances.map((att) => ({
			userId: att.userId,
			userName: att.user?.name || "Unknown",
			userEmail: att.user?.email,
			position: att.user?.position,
			department: att.user?.department,
			checkInTime: att.checkInTime ? format(att.checkInTime, "HH:mm") : null,
			checkOutTime: att.checkOutTime ? format(att.checkOutTime, "HH:mm") : null,
			status: att.status,
			isCheckedIn: !!att.checkInTime && !att.checkOutTime,
		}));
	}
}
