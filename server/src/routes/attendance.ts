import { Router, RequestHandler } from "express";
import { rateLimit } from "express-rate-limit";
import { AttendanceController } from "../controllers/attendance.controller";
import { authenticate, authorize } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { checkInValidator, checkOutValidator } from "@middlewares/validators/attendance.validator";
import { UserRole } from "@models/user";

const attendanceRouter = Router();

// Rate Limiter: 5 failed attempts per 10 minutes
const attendanceLimiter = rateLimit({
	windowMs: 10 * 60 * 1000, // 10 minutes
	limit: 5,
	skipSuccessfulRequests: true,
	message: {
		status: 429,
		message: "Too many failed attempts, please try again after 10 minutes",
	},
	keyGenerator: (req) => {
		// Use user ID if available (authenticated), otherwise IP
		return (req as any).user.id || req.ip;
	},
});

// --- Attendance Routes (Employee) ---
attendanceRouter.post(
	"/attendance/check-in",
	authenticate,
	attendanceLimiter as unknown as RequestHandler,
	checkInValidator,
	AttendanceController.checkIn,
	errorHandler
);
attendanceRouter.post(
	"/attendance/check-out",
	authenticate,
	attendanceLimiter as unknown as RequestHandler,
	checkOutValidator,
	AttendanceController.checkOut,
	errorHandler
);
attendanceRouter.get(
	"/attendance/history",
	authenticate,
	AttendanceController.getHistory,
	errorHandler
);

// --- Admin/Manager Routes ---
attendanceRouter.get(
	"/attendance/monitor",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AttendanceController.getDailyMonitor,
	errorHandler
);

attendanceRouter.post(
	"/attendance/manual",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AttendanceController.manualEntry,
	errorHandler
);

export default attendanceRouter;
