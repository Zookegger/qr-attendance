import { Router } from "express";
import { AuthController } from "@controllers/auth.controller";
import { authenticate } from "@middlewares/auth.middleware";
import { errorHandler } from "@middlewares/error.middleware";
import { changePasswordValidator } from "@middlewares/validators/auth.validator";

const authRouter = Router();

// --- Auth Routes ---
authRouter.post("/auth/login", AuthController.login, errorHandler);
authRouter.post("/auth/logout", authenticate, AuthController.logout, errorHandler);
authRouter.post("/auth/refresh", AuthController.refresh, errorHandler);
authRouter.get("/auth/me", authenticate, AuthController.me, errorHandler);
authRouter.get("/auth/reset-password", AuthController.resetPasswordLanding, errorHandler);
authRouter.post("/auth/reset-password", AuthController.resetPassword, errorHandler);
<<<<<<< HEAD
authRouter.post("/auth/change-password", authenticate, changePasswordValidator, AuthController.changePassword, errorHandler);

authRouter.post("/auth/update-fcm-token", authenticate, AuthController.updateFcmToken, errorHandler);
=======
>>>>>>> 2b987e63c41171be42634f317c09b78ab48e0fd8

export default authRouter;
