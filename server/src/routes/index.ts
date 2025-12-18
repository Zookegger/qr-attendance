import { Router } from 'express';
import { AuthController } from '@controllers/auth.controller';
import { AttendanceController } from '@controllers/attendance.controller';
import { AdminController } from '@controllers/admin.controller';
import { authenticate, authorize } from '@middlewares/auth.middleware';
import { HealthController } from '@controllers/health.controller';

const router = Router();
const healthController = new HealthController();

router.get('/health', healthController.getHealth);

// --- Auth Routes ---
router.post('/auth/register', AuthController.register);
router.post('/auth/login', AuthController.login);
router.post('/auth/refresh', AuthController.refresh);
router.get('/auth/me', authenticate, AuthController.me);

// --- Attendance Routes (Employee) ---
router.post('/attendance/check-in', authenticate, AttendanceController.checkIn);
router.post('/attendance/check-out', authenticate, AttendanceController.checkOut);
router.get('/attendance/history', authenticate, AttendanceController.getHistory);

// --- Admin Routes ---
router.get('/admin/qr', authenticate, authorize(['admin']), AdminController.generateQR);
router.get('/admin/config', authenticate, authorize(['admin']), AdminController.getOfficeConfig);
router.put('/admin/config', authenticate, authorize(['admin']), AdminController.updateOfficeConfig);
router.get('/admin/report', authenticate, authorize(['admin']), AdminController.exportReport);

export default router;
