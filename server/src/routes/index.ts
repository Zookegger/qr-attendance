import { Router } from "express";
import { HealthController } from "@controllers/health.controller";
import authRouter from "./auth";
import adminRouter from "./admin";
import attendanceRouter from "./attendance";
import requestRouter from "./request";
import workshiftRouter from "./workshift";
import scheduleRouter from "./schedule";

const router = Router();
const healthController = new HealthController();

router.get("/health", healthController.getHealth);

// --- Auth Routes ---
router.use(authRouter);

// --- Attendance Routes (Employee) ---
router.use(attendanceRouter);

// --- Request Routes ---
router.use(requestRouter);

// --- Schedule Routes ---
router.use(scheduleRouter);

// --- Workshift Routes ---
router.use(workshiftRouter);

// --- Admin Routes ---
router.use(adminRouter);

export default router;
