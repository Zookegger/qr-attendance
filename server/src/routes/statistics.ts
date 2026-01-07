import { Router } from "express";
import StatisticsController from "@controllers/statistics.controller";
import { authenticate, authorize } from "@middlewares/auth.middleware";
import { UserRole } from "@models/user";

const router = Router();

// Personal statistics (any authenticated user)
router.get(
	"/personal/:userId",
	authenticate,
	StatisticsController.getPersonalStats
);

router.get(
	"/today/:userId",
	authenticate,
	StatisticsController.getTodayShift
);

// Team statistics (managers and admins only)
router.get(
	"/team",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	StatisticsController.getTeamStats
);

router.get(
	"/team/details",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	StatisticsController.getTeamAttendanceDetails
);

export default router;
