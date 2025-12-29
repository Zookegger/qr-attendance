import { Router } from "express";
import { AdminController } from "../controllers/admin.controller";
import { authenticate, authorize } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { updateOfficeConfigValidator, addUserValidator, updateUserValidator, deleteUserValidator, listUserSessionValidator, revokeUserSessionValidator } from "@middlewares/validators/admin.validator";
import { UserRole } from "@models/user";

const adminRouter = Router();

// --- Admin Routes ---
adminRouter.get(
	"/admin/qr",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AdminController.generateQR,
	errorHandler
);
adminRouter.get(
	"/admin/config",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AdminController.getOfficeConfig,
	errorHandler
);
adminRouter.put(
	"/admin/config",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	updateOfficeConfigValidator,
	AdminController.updateOfficeConfig,
	errorHandler
);
adminRouter.get(
	"/admin/report",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AdminController.exportReport,
	errorHandler
);
adminRouter.post(
	"/admin/users",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	addUserValidator,
	AdminController.addUser,
	errorHandler
);
adminRouter.put(
	"/admin/users/:id",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	updateUserValidator,
	AdminController.updateUser,
	errorHandler
);
adminRouter.get(
	"/admin/users",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	AdminController.listUsers,
	errorHandler
);
adminRouter.delete(
	"/admin/users/:id",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	deleteUserValidator,
	AdminController.deleteUser,
	errorHandler
);
adminRouter.get(
	"/admin/users/:id/sessions",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	listUserSessionValidator,
	AdminController.listUserSession,
	errorHandler
);
adminRouter.delete(
	"/admin/sessions/:id",
	authenticate,
	authorize([UserRole.ADMIN, UserRole.MANAGER]),
	revokeUserSessionValidator,
	AdminController.revokeUserSession,
	errorHandler
);

export default adminRouter;
