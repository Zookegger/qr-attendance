import { Router } from "express";
import { AttendanceController } from "../controllers/attendance.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { checkInValidator, checkOutValidator } from "@middlewares/validators/attendance.validator";

const attendanceRouter = Router();

// --- Attendance Routes (Employee) ---
attendanceRouter.post(
	"/attendance/check-in",
	authenticate,
	checkInValidator,
	AttendanceController.checkIn,
	errorHandler
);
attendanceRouter.post(
	"/attendance/check-out",
	authenticate,
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

export default attendanceRouter;
