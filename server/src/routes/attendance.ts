import { Router } from 'express';
import { AttendanceController } from '../controllers/attendance.controller';
import { authenticate } from '@middlewares/auth.middleware';

const attendanceRouter = Router();

// --- Attendance Routes (Employee) ---
attendanceRouter.post('/attendance/check-in', authenticate, AttendanceController.checkIn);
attendanceRouter.post('/attendance/check-out', authenticate, AttendanceController.checkOut);
attendanceRouter.get('/attendance/history', authenticate, AttendanceController.getHistory);

export default attendanceRouter;