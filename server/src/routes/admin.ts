import { Router } from "express";
import { AdminController } from "../controllers/admin.controller";
import { authenticate, authorize } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";

const adminRouter = Router();

// --- Admin Routes ---
adminRouter.get(
	"/admin/qr",
	authenticate,
	authorize(["admin"]),
	AdminController.generateQR,
	errorHandler
);
adminRouter.get(
	"/admin/config",
	authenticate,
	authorize(["admin"]),
	AdminController.getOfficeConfig,
	errorHandler
);
adminRouter.put(
	"/admin/config",
	authenticate,
	authorize(["admin"]),
	AdminController.updateOfficeConfig,
	errorHandler
);
adminRouter.get(
	"/admin/report",
	authenticate,
	authorize(["admin"]),
	AdminController.exportReport,
	errorHandler
);

export default adminRouter;
